/**
 * Refer to https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-js/blob/master/examples/viewer.js
 */

import EventEmitter from 'events';
import KinesisVideo from 'aws-sdk/clients/kinesisvideo';
import KinesisVideoSignalingChannels from 'aws-sdk/clients/kinesisvideosignalingchannels';
import { SignalingClient, Role } from 'amazon-kinesis-video-streams-webrtc';
import { v4 as uuidv4 } from 'uuid';

interface ViewerOptions {
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

class Viewer extends EventEmitter {
    clientId: string;
    options: ViewerOptions;
    remoteView: HTMLVideoElement;
    signalingClient: SignalingClient;
    peerConnection: RTCPeerConnection;
    dataChannel: RTCDataChannel;
    peerConnectionStatsInterval: NodeJS.Timeout;
    remoteStream: MediaStream;

    constructor(options: Partial<ViewerOptions> = {}) {
        super();
        this.clientId = uuidv4();
        this.options = {
            region: null,
            channelName: null,
            openDataChannel: false,
            useTrickleICE: true,
            natTraversalDisabled: false,
            forceTURN: false,
            accessKeyId: null,
            secretAccessKey: null,
            ...options,
        };
        this.remoteView = null;
        this.signalingClient = null;
        this.peerConnection = null;
        this.dataChannel = null;
        this.peerConnectionStatsInterval = null;
        this.remoteStream = null;
    }

    async start(remoteView: HTMLVideoElement) {
        this.remoteView = remoteView;

        // Create KVS client
        const kinesisVideoClient = new KinesisVideo({
            region: this.options.region,
            accessKeyId: this.options.accessKeyId,
            secretAccessKey: this.options.secretAccessKey,
            sessionToken: this.options.sessionToken,
            endpoint: this.options.endpoint,
            correctClockSkew: true,
        });

        // Get signaling channel ARN
        const describeSignalingChannelResponse = await kinesisVideoClient
            .describeSignalingChannel({
                ChannelName: this.options.channelName,
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
            region: this.options.region,
            accessKeyId: this.options.accessKeyId,
            secretAccessKey: this.options.secretAccessKey,
            sessionToken: this.options.sessionToken,
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
        if (!this.options.natTraversalDisabled && !this.options.forceTURN) {
            iceServers.push({ urls: `stun:stun.kinesisvideo.${this.options.region}.amazonaws.com:443` });
        }
        if (!this.options.natTraversalDisabled) {
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
            region: this.options.region,
            credentials: {
                accessKeyId: this.options.accessKeyId,
                secretAccessKey: this.options.secretAccessKey,
                sessionToken: this.options.sessionToken,
            },
            systemClockOffset: kinesisVideoClient.config.systemClockOffset,
        });

        const configuration: RTCConfiguration = {
            iceServers,
            iceTransportPolicy: this.options.forceTURN ? 'relay' : 'all',
        };
        this.peerConnection = new RTCPeerConnection(configuration);
        if (this.options.openDataChannel) {
            this.dataChannel = this.peerConnection.createDataChannel('kvsDataChannel');
            this.peerConnection.ondatachannel = event => {
                event.channel.onmessage = message => this.emit('message', message);
            };
        }

        // Poll for connection stats
        this.peerConnectionStatsInterval = setInterval(() => this.peerConnection.getStats().then(stats => this.emit('stats', stats)), 1000);

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
            if (this.options.useTrickleICE) {
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
                if (this.options.useTrickleICE) {
                    console.log('[VIEWER] Sending ICE candidate');
                    this.signalingClient.sendIceCandidate(candidate);
                }
            } else {
                console.log('[VIEWER] All ICE candidates have been generated');

                // When trickle ICE is disabled, send the offer now that all the ICE candidates have ben generated.
                if (!this.options.useTrickleICE) {
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
