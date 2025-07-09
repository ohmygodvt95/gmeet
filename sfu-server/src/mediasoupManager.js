const mediasoup = require('mediasoup');
const config = require('./config');

class MediaSoupManager {
  constructor() {
    this.workers = [];
    this.routers = new Map(); // roomId -> router
    this.transports = new Map(); // transportId -> transport
    this.producers = new Map(); // producerId -> producer
    this.consumers = new Map(); // consumerId -> consumer
    this.peers = new Map(); // peerId -> peer info
    this.rooms = new Map(); // roomId -> room info
    
    this.workerIndex = 0;
  }

  async init() {
    try {
      // Create MediaSoup workers
      const numWorkers = process.env.MEDIASOUP_WORKERS || require('os').cpus().length;
      
      console.log(`🏭 Creating ${numWorkers} MediaSoup workers...`);
      
      for (let i = 0; i < numWorkers; i++) {
        const worker = await mediasoup.createWorker({
          logLevel: config.mediasoup.worker.logLevel,
          logTags: config.mediasoup.worker.logTags,
          rtcMinPort: config.mediasoup.worker.rtcMinPort,
          rtcMaxPort: config.mediasoup.worker.rtcMaxPort,
        });

        worker.on('died', () => {
          console.error(`💀 MediaSoup worker ${worker.pid} died, exiting in 2 seconds...`);
          setTimeout(() => process.exit(1), 2000);
        });

        this.workers.push(worker);
        console.log(`✅ Worker ${i + 1} created with PID ${worker.pid}`);
      }
      
      console.log('🎉 MediaSoup workers initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize MediaSoup workers:', error);
      throw error;
    }
  }

  getNextWorker() {
    const worker = this.workers[this.workerIndex];
    this.workerIndex = (this.workerIndex + 1) % this.workers.length;
    return worker;
  }

  async createRouter(roomId) {
    try {
      if (this.routers.has(roomId)) {
        return this.routers.get(roomId);
      }

      const worker = this.getNextWorker();
      const router = await worker.createRouter({
        mediaCodecs: config.mediasoup.router.mediaCodecs,
      });

      this.routers.set(roomId, router);
      
      // Initialize room
      this.rooms.set(roomId, {
        id: roomId,
        router,
        peers: new Map(),
        createdAt: new Date(),
      });

      console.log(`📡 Router created for room ${roomId}`);
      return router;
    } catch (error) {
      console.error(`❌ Failed to create router for room ${roomId}:`, error);
      throw error;
    }
  }

  async createWebRtcTransport(roomId, peerId, direction) {
    try {
      const router = await this.createRouter(roomId);
      
      const transport = await router.createWebRtcTransport({
        ...config.mediasoup.webRtcTransport,
        enableUdp: true,
        enableTcp: true,
        preferUdp: true,
      });

      const transportId = `${peerId}_${direction}_${Date.now()}`;
      
      this.transports.set(transportId, {
        transport,
        peerId,
        roomId,
        direction,
      });

      // Store transport in peer info
      const peer = this.getPeer(peerId, roomId);
      if (direction === 'send') {
        peer.sendTransport = { id: transportId, transport };
      } else {
        peer.recvTransport = { id: transportId, transport };
      }

      console.log(`🚚 ${direction} transport created for peer ${peerId} in room ${roomId}`);

      return {
        id: transportId,
        iceParameters: transport.iceParameters,
        iceCandidates: transport.iceCandidates,
        dtlsParameters: transport.dtlsParameters,
      };
    } catch (error) {
      console.error(`❌ Failed to create transport:`, error);
      throw error;
    }
  }

  async connectTransport(transportId, dtlsParameters) {
    try {
      const transportInfo = this.transports.get(transportId);
      if (!transportInfo) {
        throw new Error(`Transport ${transportId} not found`);
      }

      await transportInfo.transport.connect({ dtlsParameters });
      console.log(`🔗 Transport ${transportId} connected`);
    } catch (error) {
      console.error(`❌ Failed to connect transport ${transportId}:`, error);
      throw error;
    }
  }

  async produce(transportId, rtpParameters, kind, appData = {}) {
    try {
      const transportInfo = this.transports.get(transportId);
      if (!transportInfo) {
        throw new Error(`Transport ${transportId} not found`);
      }

      // Log detailed info for debugging
      console.log(`⏩ Produce request for ${kind} on transport ${transportId}`, {
        transportExists: !!transportInfo.transport,
        transportDirection: transportInfo.direction,
        roomId: transportInfo.roomId,
        peerId: transportInfo.peerId
      });

      // Validate RTP parameters for more detailed error messages
      if (!rtpParameters || !rtpParameters.codecs || rtpParameters.codecs.length === 0) {
        console.error(`❌ Invalid RTP parameters for ${kind}:`, rtpParameters);
        throw new Error(`Invalid RTP parameters for ${kind}`);
      }

      console.log(`✓ RTP codecs for ${kind}:`, rtpParameters.codecs.map(c => c.mimeType));

      const producer = await transportInfo.transport.produce({
        kind,
        rtpParameters,
        appData: { ...appData, peerId: transportInfo.peerId, transportId },
      });

      const producerId = producer.id;
      this.producers.set(producerId, {
        producer,
        peerId: transportInfo.peerId,
        roomId: transportInfo.roomId,
        kind,
      });

      // Store producer in peer info
      const peer = this.getPeer(transportInfo.peerId, transportInfo.roomId);
      peer.producers.set(producerId, producer);

      console.log(`📹 Producer created successfully: ${producerId} (${kind}) for peer ${transportInfo.peerId}`);

      // Notify other peers in room about new producer
      this.notifyPeersAboutProducer(transportInfo.roomId, transportInfo.peerId, producerId, kind);

      return { id: producerId };
    } catch (error) {
      console.error(`❌ Failed to produce ${kind}:`, error);
      throw error;
    }
  }

  async consume(consumerPeerId, producerId, rtpCapabilities) {
    try {
      const producerInfo = this.producers.get(producerId);
      if (!producerInfo) {
        throw new Error(`Producer ${producerId} not found`);
      }

      const consumerPeer = this.peers.get(consumerPeerId);
      if (!consumerPeer || !consumerPeer.recvTransport) {
        throw new Error(`Consumer peer ${consumerPeerId} or recv transport not found`);
      }

      const router = this.routers.get(producerInfo.roomId);
      if (!router) {
        throw new Error(`Router for room ${producerInfo.roomId} not found`);
      }

      if (!router.canConsume({ producerId, rtpCapabilities })) {
        throw new Error('Cannot consume producer');
      }

      const consumer = await consumerPeer.recvTransport.transport.consume({
        producerId,
        rtpCapabilities,
        paused: false,
      });

      const consumerId = consumer.id;
      this.consumers.set(consumerId, {
        consumer,
        consumerPeerId,
        producerId,
        roomId: producerInfo.roomId,
      });

      // Store consumer in peer info
      consumerPeer.consumers.set(consumerId, consumer);

      console.log(`🍽️  Consumer created: ${consumerId} for peer ${consumerPeerId}`);

      return {
        id: consumerId,
        producerId,
        kind: consumer.kind,
        rtpParameters: consumer.rtpParameters,
      };
    } catch (error) {
      console.error(`❌ Failed to consume:`, error);
      throw error;
    }
  }

  async pauseConsumer(consumerId) {
    try {
      const consumerInfo = this.consumers.get(consumerId);
      if (!consumerInfo) {
        throw new Error(`Consumer ${consumerId} not found`);
      }

      await consumerInfo.consumer.pause();
      console.log(`⏸️  Consumer ${consumerId} paused`);
    } catch (error) {
      console.error(`❌ Failed to pause consumer:`, error);
      throw error;
    }
  }

  async resumeConsumer(consumerId) {
    try {
      const consumerInfo = this.consumers.get(consumerId);
      if (!consumerInfo) {
        throw new Error(`Consumer ${consumerId} not found`);
      }

      await consumerInfo.consumer.resume();
      console.log(`▶️  Consumer ${consumerId} resumed`);
    } catch (error) {
      console.error(`❌ Failed to resume consumer:`, error);
      throw error;
    }
  }

  async closeProducer(producerId) {
    try {
      const producerInfo = this.producers.get(producerId);
      if (!producerInfo) {
        return;
      }

      // Close producer
      producerInfo.producer.close();
      this.producers.delete(producerId);

      // Remove from peer
      const peer = this.getPeer(producerInfo.peerId, producerInfo.roomId);
      peer.producers.delete(producerId);

      // Close all consumers of this producer
      const consumersToClose = [];
      this.consumers.forEach((consumerInfo, consumerId) => {
        if (consumerInfo.producerId === producerId) {
          consumersToClose.push(consumerId);
        }
      });

      for (const consumerId of consumersToClose) {
        await this.closeConsumer(consumerId);
      }

      console.log(`🚫 Producer ${producerId} closed`);

      // Notify other peers
      this.notifyPeersAboutProducerClosed(producerInfo.roomId, producerId);
    } catch (error) {
      console.error(`❌ Failed to close producer:`, error);
    }
  }

  async closeConsumer(consumerId) {
    try {
      const consumerInfo = this.consumers.get(consumerId);
      if (!consumerInfo) {
        return;
      }

      // Close consumer
      consumerInfo.consumer.close();
      this.consumers.delete(consumerId);

      // Remove from peer
      const peer = this.peers.get(consumerInfo.consumerPeerId);
      if (peer) {
        peer.consumers.delete(consumerId);
      }

      console.log(`🚫 Consumer ${consumerId} closed`);
    } catch (error) {
      console.error(`❌ Failed to close consumer:`, error);
    }
  }

  getPeer(peerId, roomId) {
    if (!this.peers.has(peerId)) {
      this.peers.set(peerId, {
        id: peerId,
        roomId,
        sendTransport: null,
        recvTransport: null,
        producers: new Map(),
        consumers: new Map(),
        joinedAt: new Date(),
      });

      // Add peer to room
      const room = this.rooms.get(roomId);
      if (room) {
        room.peers.set(peerId, this.peers.get(peerId));
      }
    }
    return this.peers.get(peerId);
  }

  removePeer(peerId) {
    const peer = this.peers.get(peerId);
    if (!peer) return;

    // Close all producers
    const producersToClose = Array.from(peer.producers.keys());
    producersToClose.forEach(producerId => {
      this.closeProducer(producerId);
    });

    // Close all consumers
    const consumersToClose = Array.from(peer.consumers.keys());
    consumersToClose.forEach(consumerId => {
      this.closeConsumer(consumerId);
    });

    // Close transports
    if (peer.sendTransport) {
      peer.sendTransport.transport.close();
      this.transports.delete(peer.sendTransport.id);
    }
    if (peer.recvTransport) {
      peer.recvTransport.transport.close();
      this.transports.delete(peer.recvTransport.id);
    }

    // Remove from room
    const room = this.rooms.get(peer.roomId);
    if (room) {
      room.peers.delete(peerId);
    }

    // Remove peer
    this.peers.delete(peerId);

    console.log(`👋 Peer ${peerId} removed`);
  }

  async getRouterRtpCapabilities(roomId) {
    // Ensure router exists
    await this.createRouter(roomId);
    
    const router = this.routers.get(roomId);
    if (!router) {
      throw new Error(`Router for room ${roomId} not found after creation`);
    }
    return router.rtpCapabilities;
  }

  getRoomProducers(roomId, excludePeerId = null) {
    const room = this.rooms.get(roomId);
    if (!room) return [];

    const producers = [];
    room.peers.forEach((peer, peerId) => {
      if (peerId !== excludePeerId) {
        peer.producers.forEach((producer, producerId) => {
          producers.push({
            id: producerId,
            peerId,
            kind: producer.kind,
          });
        });
      }
    });

    return producers;
  }

  notifyPeersAboutProducer(roomId, producerPeerId, producerId, kind) {
    // This will be implemented when we integrate with Socket.IO
    console.log(`📢 Notifying peers in room ${roomId} about new producer ${producerId} (${kind}) from peer ${producerPeerId}`);
  }

  notifyPeersAboutProducerClosed(roomId, producerId) {
    // This will be implemented when we integrate with Socket.IO
    console.log(`📢 Notifying peers in room ${roomId} about closed producer ${producerId}`);
  }

  async closeRoom(roomId) {
    const room = this.rooms.get(roomId);
    if (!room) return;

    // Remove all peers
    const peerIds = Array.from(room.peers.keys());
    peerIds.forEach(peerId => {
      this.removePeer(peerId);
    });

    // Close router
    room.router.close();
    this.routers.delete(roomId);
    this.rooms.delete(roomId);

    console.log(`🏠 Room ${roomId} closed`);
  }

  getStats() {
    return {
      workers: this.workers.length,
      routers: this.routers.size,
      rooms: this.rooms.size,
      peers: this.peers.size,
      transports: this.transports.size,
      producers: this.producers.size,
      consumers: this.consumers.size,
    };
  }
}

module.exports = MediaSoupManager;
