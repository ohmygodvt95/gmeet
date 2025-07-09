const jwt = require('jsonwebtoken');
const config = require('./config');

class SFUSocketManager {
  constructor(io, mediaSoupManager) {
    this.io = io;
    this.mediaSoup = mediaSoupManager;
    this.peers = new Map(); // socketId -> peer info
    this.rooms = new Map(); // roomId -> Set of socketIds
    
    this.setupEventHandlers();
  }

  setupEventHandlers() {
    this.io.use(this.authenticateSocket.bind(this));
    
    this.io.on('connection', (socket) => {
      console.log(`🔌 SFU Client connected: ${socket.user.username} (${socket.id})`);
      
      // Store socket-user mapping
      this.peers.set(socket.id, {
        socketId: socket.id,
        userId: socket.user.userId,
        username: socket.user.username,
        roomId: null,
        rtpCapabilities: null,
      });

      // SFU-specific events
      socket.on('join-room', this.handleJoinRoom.bind(this, socket));
      socket.on('leave-room', this.handleLeaveRoom.bind(this, socket));
      socket.on('get-router-rtp-capabilities', this.handleGetRouterRtpCapabilities.bind(this, socket));
      socket.on('create-webrtc-transport', this.handleCreateWebRtcTransport.bind(this, socket));
      socket.on('connect-transport', this.handleConnectTransport.bind(this, socket));
      socket.on('produce', this.handleProduce.bind(this, socket));
      socket.on('consume', this.handleConsume.bind(this, socket));
      socket.on('resume-consumer', this.handleResumeConsumer.bind(this, socket));
      socket.on('pause-consumer', this.handlePauseConsumer.bind(this, socket));
      socket.on('close-producer', this.handleCloseProducer.bind(this, socket));
      socket.on('get-producers', this.handleGetProducers.bind(this, socket));

      // Handle disconnect
      socket.on('disconnect', this.handleDisconnect.bind(this, socket));
    });
  }

  async authenticateSocket(socket, next) {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication token required'));
      }

      const decoded = jwt.verify(token, config.jwt.secret);
      socket.user = decoded;
      next();
    } catch (error) {
      next(new Error('Invalid authentication token'));
    }
  }

  async handleJoinRoom(socket, data) {
    try {
      const { roomId } = data;
      const peer = this.peers.get(socket.id);
      
      if (!peer) {
        socket.emit('error', { message: 'Peer not found' });
        return;
      }

      // Update peer room info
      peer.roomId = roomId;
      this.peers.set(socket.id, peer);

      // Add to room tracking
      if (!this.rooms.has(roomId)) {
        this.rooms.set(roomId, new Set());
      }
      this.rooms.get(roomId).add(socket.id);

      // Join socket room
      socket.join(roomId);

      // Ensure router exists for the room
      await this.mediaSoup.createRouter(roomId);

      // Create MediaSoup peer
      this.mediaSoup.getPeer(socket.id, roomId);

      console.log(`🏠 Peer ${socket.user.username} joined SFU room ${roomId}`);

      socket.emit('joined-room', { roomId });

      // Notify other peers
      socket.to(roomId).emit('peer-joined', {
        peerId: socket.id,
        username: socket.user.username,
      });

    } catch (error) {
      console.error('Error joining SFU room:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  }

  async handleLeaveRoom(socket) {
    try {
      const peer = this.peers.get(socket.id);
      if (!peer || !peer.roomId) return;

      const roomId = peer.roomId;

      // Remove from room tracking
      if (this.rooms.has(roomId)) {
        this.rooms.get(roomId).delete(socket.id);
        
        // Clean up empty room
        if (this.rooms.get(roomId).size === 0) {
          this.rooms.delete(roomId);
          await this.mediaSoup.closeRoom(roomId);
        }
      }

      // Leave socket room
      socket.leave(roomId);

      // Remove MediaSoup peer
      this.mediaSoup.removePeer(socket.id);

      // Update peer info
      peer.roomId = null;
      peer.rtpCapabilities = null;

      console.log(`🚪 Peer ${socket.user.username} left SFU room ${roomId}`);

      // Notify other peers
      socket.to(roomId).emit('peer-left', {
        peerId: socket.id,
      });

    } catch (error) {
      console.error('Error leaving SFU room:', error);
    }
  }

  async handleGetRouterRtpCapabilities(socket, data) {
    try {
      const { roomId } = data;
      
      // Ensure router exists for the room
      await this.mediaSoup.createRouter(roomId);
      
      const rtpCapabilities = this.mediaSoup.getRouterRtpCapabilities(roomId);
      
      socket.emit('router-rtp-capabilities', {
        rtpCapabilities,
      });

    } catch (error) {
      console.error('Error getting router RTP capabilities:', error);
      socket.emit('error', { message: 'Failed to get router capabilities' });
    }
  }

  async handleCreateWebRtcTransport(socket, data) {
    try {
      const { direction } = data; // 'send' or 'recv'
      const peer = this.peers.get(socket.id);
      
      if (!peer || !peer.roomId) {
        socket.emit('error', { message: 'Peer not in room' });
        return;
      }

      const transportParams = await this.mediaSoup.createWebRtcTransport(
        peer.roomId,
        socket.id,
        direction
      );

      socket.emit('webrtc-transport-created', {
        direction,
        ...transportParams,
      });

    } catch (error) {
      console.error('Error creating WebRTC transport:', error);
      socket.emit('error', { message: 'Failed to create transport' });
    }
  }

  async handleConnectTransport(socket, data) {
    try {
      const { transportId, dtlsParameters } = data;
      
      await this.mediaSoup.connectTransport(transportId, dtlsParameters);
      
      socket.emit('transport-connected', { transportId });

    } catch (error) {
      console.error('Error connecting transport:', error);
      socket.emit('error', { message: 'Failed to connect transport' });
    }
  }

  async handleProduce(socket, data) {
    try {
      const { transportId, kind, rtpParameters, appData } = data;
      
      console.log(`🎙️ Socket ${socket.id} producing ${kind} on transport ${transportId}`);
      
      const result = await this.mediaSoup.produce(
        transportId,
        rtpParameters,
        kind,
        appData
      );

      console.log(`✅ Successfully created ${kind} producer ${result.id} for peer ${socket.id}`);

      socket.emit('produced', {
        id: result.id,
        kind,
      });

      // Notify other peers in room about new producer
      const peer = this.peers.get(socket.id);
      if (peer && peer.roomId) {
        console.log(`📢 Broadcasting new-producer (${kind}) to room ${peer.roomId}`);
        socket.to(peer.roomId).emit('new-producer', {
          peerId: socket.id,
          producerId: result.id,
          kind,
        });
      } else {
        console.warn(`⚠️ Cannot notify about new producer: Peer ${socket.id} not in a room`);
      }

    } catch (error) {
      console.error(`❌ Error producing ${kind} on transport ${transportId}:`, error);
      socket.emit('error', { 
        message: `Failed to produce ${kind}`,
        details: error.message
      });
    }
  }

  async handleConsume(socket, data) {
    try {
      const { producerId, rtpCapabilities } = data;
      
      const result = await this.mediaSoup.consume(
        socket.id,
        producerId,
        rtpCapabilities
      );

      socket.emit('consumed', result);

    } catch (error) {
      console.error('Error consuming:', error);
      socket.emit('error', { message: 'Failed to consume' });
    }
  }

  async handleResumeConsumer(socket, data) {
    try {
      const { consumerId } = data;
      
      await this.mediaSoup.resumeConsumer(consumerId);
      
      socket.emit('consumer-resumed', { consumerId });

    } catch (error) {
      console.error('Error resuming consumer:', error);
      socket.emit('error', { message: 'Failed to resume consumer' });
    }
  }

  async handlePauseConsumer(socket, data) {
    try {
      const { consumerId } = data;
      
      await this.mediaSoup.pauseConsumer(consumerId);
      
      socket.emit('consumer-paused', { consumerId });

    } catch (error) {
      console.error('Error pausing consumer:', error);
      socket.emit('error', { message: 'Failed to pause consumer' });
    }
  }

  async handleCloseProducer(socket, data) {
    try {
      const { producerId } = data;
      
      await this.mediaSoup.closeProducer(producerId);
      
      socket.emit('producer-closed', { producerId });

      // Notify other peers
      const peer = this.peers.get(socket.id);
      if (peer && peer.roomId) {
        socket.to(peer.roomId).emit('producer-closed', {
          peerId: socket.id,
          producerId,
        });
      }

    } catch (error) {
      console.error('Error closing producer:', error);
      socket.emit('error', { message: 'Failed to close producer' });
    }
  }

  handleGetProducers(socket) {
    try {
      const peer = this.peers.get(socket.id);
      if (!peer || !peer.roomId) {
        socket.emit('producers', { producers: [] });
        return;
      }

      const producers = this.mediaSoup.getRoomProducers(peer.roomId, socket.id);
      
      socket.emit('producers', { producers });

    } catch (error) {
      console.error('Error getting producers:', error);
      socket.emit('error', { message: 'Failed to get producers' });
    }
  }

  async handleDisconnect(socket) {
    try {
      const peer = this.peers.get(socket.id);
      
      if (peer) {
        console.log(`❌ SFU Client disconnected: ${peer.username} (${socket.id})`);
        
        // Leave room if in one
        if (peer.roomId) {
          await this.handleLeaveRoom(socket);
        }
        
        // Remove peer
        this.peers.delete(socket.id);
      }

    } catch (error) {
      console.error('Error handling SFU disconnect:', error);
    }
  }

  // Utility method to get room stats
  getRoomStats(roomId) {
    const socketIds = this.rooms.get(roomId) || new Set();
    const participants = Array.from(socketIds)
      .map(socketId => this.peers.get(socketId))
      .filter(Boolean);
    
    return {
      participantCount: participants.length,
      participants: participants.map(p => ({
        socketId: p.socketId,
        userId: p.userId,
        username: p.username,
      })),
    };
  }

  // Get SFU stats
  getStats() {
    return {
      connectedPeers: this.peers.size,
      activeRooms: this.rooms.size,
      mediaSoupStats: this.mediaSoup.getStats(),
    };
  }
}

module.exports = SFUSocketManager;
