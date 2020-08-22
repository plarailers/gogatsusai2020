import KinesisVideo from 'aws-sdk/clients/kinesisvideo';
import KinesisVideoSignalingChannels from 'aws-sdk/clients/kinesisvideosignalingchannels';
import { SignalingClient, Role } from 'amazon-kinesis-video-streams-webrtc';
import { v4 as uuidv4 } from 'uuid';

interface FormValues {
    region: string;
    channelName: string;
    openDataChannel: boolean;
    useTrickleICE: boolean;
    natTraversalDisabled: boolean;
    forceTURN: boolean;
    accessKeyId: string;
    endpoint?: string;
    secretAccessKey: string;
    sessionToken?: string;
}

class Viewer {
    clientId: string;
    remoteView: HTMLVideoElement;
    signalingClient: SignalingClient;
    peerConnection: RTCPeerConnection;
    dataChannel: RTCDataChannel;
    peerConnectionStatsInterval: NodeJS.Timeout;
    remoteStream: MediaStream;

    constructor() {
        this.clientId = uuidv4();
    }

    async start(remoteView: HTMLVideoElement, formValues: FormValues, onStatsReport, onRemoteDataMessage) {
        this.remoteView = remoteView;

        // Create KVS client
        const kinesisVideoClient = new KinesisVideo({
            region: formValues.region,
            accessKeyId: formValues.accessKeyId,
            secretAccessKey: formValues.secretAccessKey,
            sessionToken: formValues.sessionToken,
            endpoint: formValues.endpoint,
            correctClockSkew: true,
        });

        // Get signaling channel ARN
        const describeSignalingChannelResponse = await kinesisVideoClient
            .describeSignalingChannel({
                ChannelName: formValues.channelName,
            })
            .promise();
        const channelARN = describeSignalingChannelResponse.ChannelInfo.ChannelARN;
        console.log('[VIEWER] Channel ARN: ', channelARN);

        // Get signaling channel endpoints
        const getSignalingChannelEndpointResponse = await kinesisVideoClient
            .getSignalingChannelEndpoint({
                ChannelARN: channelARN,
                SingleMasterChannelEndpointConfiguration: {
                    Protocols: ['WSS', 'HTTPS'],
                    Role: Role.VIEWER,
                },
            })
            .promise();
        const endpointsByProtocol = getSignalingChannelEndpointResponse.ResourceEndpointList.reduce((endpoints, endpoint) => {
            endpoints[endpoint.Protocol] = endpoint.ResourceEndpoint;
            return endpoints;
        }, {});
        console.log('[VIEWER] Endpoints: ', endpointsByProtocol);

        const kinesisVideoSignalingChannelsClient = new KinesisVideoSignalingChannels({
            region: formValues.region,
            accessKeyId: formValues.accessKeyId,
            secretAccessKey: formValues.secretAccessKey,
            sessionToken: formValues.sessionToken,
            endpoint: endpointsByProtocol['HTTPS'],
            correctClockSkew: true,
        });

        // Get ICE server configuration
        const getIceServerConfigResponse = await kinesisVideoSignalingChannelsClient
            .getIceServerConfig({
                ChannelARN: channelARN,
            })
            .promise();
        const iceServers = [];
        if (!formValues.natTraversalDisabled && !formValues.forceTURN) {
            iceServers.push({ urls: `stun:stun.kinesisvideo.${formValues.region}.amazonaws.com:443` });
        }
        if (!formValues.natTraversalDisabled) {
            getIceServerConfigResponse.IceServerList.forEach(iceServer =>
                iceServers.push({
                    urls: iceServer.Uris,
                    username: iceServer.Username,
                    credential: iceServer.Password,
                }),
            );
        }
        console.log('[VIEWER] ICE servers: ', iceServers);

        // Create Signaling Client
        this.signalingClient = new SignalingClient({
            channelARN,
            channelEndpoint: endpointsByProtocol['WSS'],
            clientId: this.clientId,
            role: Role.VIEWER,
            region: formValues.region,
            credentials: {
                accessKeyId: formValues.accessKeyId,
                secretAccessKey: formValues.secretAccessKey,
                sessionToken: formValues.sessionToken,
            },
            systemClockOffset: kinesisVideoClient.config.systemClockOffset,
        });

        const configuration: RTCConfiguration = {
            iceServers,
            iceTransportPolicy: formValues.forceTURN ? 'relay' : 'all',
        };
        this.peerConnection = new RTCPeerConnection(configuration);
        if (formValues.openDataChannel) {
            this.dataChannel = this.peerConnection.createDataChannel('kvsDataChannel');
            this.peerConnection.ondatachannel = event => {
                event.channel.onmessage = onRemoteDataMessage;
            };
        }

        // Poll for connection stats
        this.peerConnectionStatsInterval = setInterval(() => this.peerConnection.getStats().then(onStatsReport), 1000);

        this.signalingClient.on('open', async () => {
            console.log('[VIEWER] Connected to signaling service');

            // Create an SDP offer to send to the master
            console.log('[VIEWER] Creating SDP offer');
            await this.peerConnection.setLocalDescription(
                await this.peerConnection.createOffer({
                    offerToReceiveAudio: true,
                    offerToReceiveVideo: true,
                }),
            );

            // When trickle ICE is enabled, send the offer now and then send ICE candidates as they are generated. Otherwise wait on the ICE candidates.
            if (formValues.useTrickleICE) {
                console.log('[VIEWER] Sending SDP offer');
                this.signalingClient.sendSdpOffer(this.peerConnection.localDescription);
            }
            console.log('[VIEWER] Generating ICE candidates');
        });

        this.signalingClient.on('sdpAnswer', async answer => {
            // Add the SDP answer to the peer connection
            console.log('[VIEWER] Received SDP answer');
            await this.peerConnection.setRemoteDescription(answer);
        });

        this.signalingClient.on('iceCandidate', candidate => {
            // Add the ICE candidate received from the MASTER to the peer connection
            console.log('[VIEWER] Received ICE candidate');
            this.peerConnection.addIceCandidate(candidate);
        });

        this.signalingClient.on('close', () => {
            console.log('[VIEWER] Disconnected from signaling channel');
        });

        this.signalingClient.on('error', error => {
            console.error('[VIEWER] Signaling client error: ', error);
        });

        // Send any ICE candidates to the other peer
        this.peerConnection.addEventListener('icecandidate', ({ candidate }) => {
            if (candidate) {
                console.log('[VIEWER] Generated ICE candidate');

                // When trickle ICE is enabled, send the ICE candidates as they are generated.
                if (formValues.useTrickleICE) {
                    console.log('[VIEWER] Sending ICE candidate');
                    this.signalingClient.sendIceCandidate(candidate);
                }
            } else {
                console.log('[VIEWER] All ICE candidates have been generated');

                // When trickle ICE is disabled, send the offer now that all the ICE candidates have ben generated.
                if (!formValues.useTrickleICE) {
                    console.log('[VIEWER] Sending SDP offer');
                    this.signalingClient.sendSdpOffer(this.peerConnection.localDescription);
                }
            }
        });

        // As remote tracks are received, add them to the remote view
        this.peerConnection.addEventListener('track', event => {
            console.log('[VIEWER] Received remote track');
            if (remoteView.srcObject) {
                return;
            }
            this.remoteStream = event.streams[0];
            remoteView.srcObject = this.remoteStream;
        });

        console.log('[VIEWER] Starting viewer connection');
        this.signalingClient.open();
    }

    stop() {
        console.log('[VIEWER] Stopping viewer connection');
        if (this.signalingClient) {
            this.signalingClient.close();
            this.signalingClient = null;
        }

        if (this.peerConnection) {
            this.peerConnection.close();
            this.peerConnection = null;
        }

        if (this.remoteStream) {
            this.remoteStream.getTracks().forEach(track => track.stop());
            this.remoteStream = null;
        }

        if (this.peerConnectionStatsInterval) {
            clearInterval(this.peerConnectionStatsInterval);
            this.peerConnectionStatsInterval = null;
        }

        if (this.remoteView) {
            this.remoteView.srcObject = null;
        }

        if (this.dataChannel) {
            this.dataChannel = null;
        }
    }

    sendMessage(message: string) {
        if (this.dataChannel) {
            try {
                this.dataChannel.send(message);
            } catch (e) {
                console.error('[VIEWER] Send DataChannel: ', e.toString());
            }
        }
    }
}

if (typeof window !== 'undefined') {
    window['Viewer'] = Viewer;
}
