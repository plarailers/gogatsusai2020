/**
 * Refer to https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-js/blob/master/examples/master.js
 */

import EventEmitter from 'events';
import KinesisVideo from 'aws-sdk/clients/kinesisvideo';
import KinesisVideoSignalingChannels from 'aws-sdk/clients/kinesisvideosignalingchannels';
import { SignalingClient, Role } from 'amazon-kinesis-video-streams-webrtc';

interface MasterOptions {
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

class Master extends EventEmitter {
    options: MasterOptions;
    localView: HTMLVideoElement;
    signalingClient: SignalingClient;
    peerConnectionByClientId: { [K: string]: RTCPeerConnection };
    dataChannelByClientId: { [K: string]: RTCDataChannel };
    peerConnectionStatsInterval: NodeJS.Timeout;
    localStream: MediaStream;

    constructor(options: Partial<MasterOptions> = {}) {
        super();
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
        this.localView = null;
        this.signalingClient = null;
        this.peerConnectionByClientId = {};
        this.dataChannelByClientId = {};
        this.peerConnectionStatsInterval = null;
        this.localStream = null;
    }

    async start(
        localView: HTMLVideoElement,
        constraints: MediaStreamConstraints = {
            video: true,
            audio: true,
        },
    ) {
        this.localView = localView;

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
        console.log('[MASTER] Channel ARN: ', channelARN);

        // Get signaling channel endpoints
        const getSignalingChannelEndpointResponse = await kinesisVideoClient
            .getSignalingChannelEndpoint({
                ChannelARN: channelARN,
                SingleMasterChannelEndpointConfiguration: {
                    Protocols: ['WSS', 'HTTPS'],
                    Role: Role.MASTER,
                },
            })
            .promise();
        const endpointsByProtocol = getSignalingChannelEndpointResponse.ResourceEndpointList.reduce((endpoints, endpoint) => {
            endpoints[endpoint.Protocol] = endpoint.ResourceEndpoint;
            return endpoints;
        }, {});
        console.log('[MASTER] Endpoints: ', endpointsByProtocol);

        // Create Signaling Client
        this.signalingClient = new SignalingClient({
            channelARN,
            channelEndpoint: endpointsByProtocol['WSS'],
            role: Role.MASTER,
            region: this.options.region,
            credentials: {
                accessKeyId: this.options.accessKeyId,
                secretAccessKey: this.options.secretAccessKey,
                sessionToken: this.options.sessionToken,
            },
            systemClockOffset: kinesisVideoClient.config.systemClockOffset,
        });

        // Get ICE server configuration
        const kinesisVideoSignalingChannelsClient = new KinesisVideoSignalingChannels({
            region: this.options.region,
            accessKeyId: this.options.accessKeyId,
            secretAccessKey: this.options.secretAccessKey,
            sessionToken: this.options.sessionToken,
            endpoint: endpointsByProtocol['HTTPS'],
            correctClockSkew: true,
        });
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
        console.log('[MASTER] ICE servers: ', iceServers);

        const configuration: RTCConfiguration = {
            iceServers,
            iceTransportPolicy: this.options.forceTURN ? 'relay' : 'all',
        };

        // Get a stream from the webcam and display it in the local view.
        try {
            this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
            localView.srcObject = this.localStream;
        } catch (e) {
            console.error('[MASTER] Could not find webcam');
        }

        this.signalingClient.on('open', async () => {
            console.log('[MASTER] Connected to signaling service');
        });

        this.signalingClient.on('sdpOffer', async (offer, remoteClientId) => {
            console.log('[MASTER] Received SDP offer from client: ' + remoteClientId);

            // Create a new peer connection using the offer from the given client
            const peerConnection = new RTCPeerConnection(configuration);
            this.peerConnectionByClientId[remoteClientId] = peerConnection;

            if (this.options.openDataChannel) {
                this.dataChannelByClientId[remoteClientId] = peerConnection.createDataChannel('kvsDataChannel');
                peerConnection.ondatachannel = event => {
                    event.channel.onmessage = message => this.emit('message', message);
                };
            }

            // Poll for connection stats
            if (!this.peerConnectionStatsInterval) {
                this.peerConnectionStatsInterval = setInterval(() => peerConnection.getStats().then(stats => this.emit('stats', stats)), 1000);
            }

            // Send any ICE candidates to the other peer
            peerConnection.addEventListener('icecandidate', ({ candidate }) => {
                if (candidate) {
                    console.log('[MASTER] Generated ICE candidate for client: ' + remoteClientId);

                    // When trickle ICE is enabled, send the ICE candidates as they are generated.
                    if (this.options.useTrickleICE) {
                        console.log('[MASTER] Sending ICE candidate to client: ' + remoteClientId);
                        this.signalingClient.sendIceCandidate(candidate, remoteClientId);
                    }
                } else {
                    console.log('[MASTER] All ICE candidates have been generated for client: ' + remoteClientId);

                    // When trickle ICE is disabled, send the answer now that all the ICE candidates have ben generated.
                    if (!this.options.useTrickleICE) {
                        console.log('[MASTER] Sending SDP answer to client: ' + remoteClientId);
                        this.signalingClient.sendSdpAnswer(peerConnection.localDescription, remoteClientId);
                    }
                }
            });

            // If there's no video/audio, this.localStream will be null. So, we should skip adding the tracks from it.
            if (this.localStream) {
                this.localStream.getTracks().forEach(track => peerConnection.addTrack(track, this.localStream));
            }
            await peerConnection.setRemoteDescription(offer);

            // Create an SDP answer to send back to the client
            console.log('[MASTER] Creating SDP answer for client: ' + remoteClientId);
            await peerConnection.setLocalDescription(
                await peerConnection.createAnswer({
                    offerToReceiveAudio: true,
                    offerToReceiveVideo: true,
                }),
            );

            // When trickle ICE is enabled, send the answer now and then send ICE candidates as they are generated. Otherwise wait on the ICE candidates.
            if (this.options.useTrickleICE) {
                console.log('[MASTER] Sending SDP answer to client: ' + remoteClientId);
                this.signalingClient.sendSdpAnswer(peerConnection.localDescription, remoteClientId);
            }
            console.log('[MASTER] Generating ICE candidates for client: ' + remoteClientId);
        });

        this.signalingClient.on('iceCandidate', async (candidate, remoteClientId) => {
            console.log('[MASTER] Received ICE candidate from client: ' + remoteClientId);

            // Add the ICE candidate received from the client to the peer connection
            const peerConnection = this.peerConnectionByClientId[remoteClientId];
            peerConnection.addIceCandidate(candidate);
        });

        this.signalingClient.on('close', () => {
            console.log('[MASTER] Disconnected from signaling channel');
        });

        this.signalingClient.on('error', () => {
            console.error('[MASTER] Signaling client error');
        });

        console.log('[MASTER] Starting master connection');
        this.signalingClient.open();
    }

    stop() {
        console.log('[MASTER] Stopping master connection');
        if (this.signalingClient) {
            this.signalingClient.close();
            this.signalingClient = null;
        }

        Object.keys(this.peerConnectionByClientId).forEach(clientId => {
            this.peerConnectionByClientId[clientId].close();
        });
        this.peerConnectionByClientId = {};

        if (this.localStream) {
            this.localStream.getTracks().forEach(track => track.stop());
            this.localStream = null;
        }

        if (this.peerConnectionStatsInterval) {
            clearInterval(this.peerConnectionStatsInterval);
            this.peerConnectionStatsInterval = null;
        }

        if (this.localView) {
            this.localView.srcObject = null;
        }

        if (this.dataChannelByClientId) {
            this.dataChannelByClientId = {};
        }
    }

    sendMessage(message: string) {
        Object.keys(this.dataChannelByClientId).forEach(clientId => {
            try {
                this.dataChannelByClientId[clientId].send(message);
            } catch (e) {
                console.error('[MASTER] Send DataChannel: ', e.toString());
            }
        });
    }
}

if (typeof window !== 'undefined') {
    window['Master'] = Master;
}
