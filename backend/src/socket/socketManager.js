const jwt = require('jsonwebtoken');
const Room = require('../models/Room');
const database = require('../config/database');
const config = require('../config');

class SocketManager {
  constructor(io) {
    this.io = io;
    this.rooms = new Map(); // roomId -> Set of socket ids
    this.userSockets = new Map(); // userId -> Set of socket ids
    this.socketUsers = new Map(); // socketId -> userData
    this.redis = database.getRedis();
    
    this.setupEventHandlers();
  }

  setupEventHandlers() {
    this.io.use(this.authenticateSocket.bind(this));
    
    this.io.on('connection', (socket) => {
      console.log(`✅ User connected: ${socket.user.username} (${socket.id})`);
      
      // Store socket-user mapping
      this.socketUsers.set(socket.id, socket.user);
      
      // Add to user sockets map
      if (!this.userSockets.has(socket.user.userId)) {
        this.userSockets.set(socket.user.userId, new Set());
      }
      this.userSockets.get(socket.user.userId).add(socket.id);

      // Store session in Redis
      this.storeSocketSession(socket.id, socket.user);

      // Handle room joining
      socket.on('join-room', this.handleJoinRoom.bind(this, socket));
      
      // Handle leaving room
      socket.on('leave-room', this.handleLeaveRoom.bind(this, socket));
      
      // Handle WebRTC signaling
      socket.on('offer', this.handleOffer.bind(this, socket));
      socket.on('answer', this.handleAnswer.bind(this, socket));
      socket.on('ice-candidate', this.handleIceCandidate.bind(this, socket));
      
      // Handle media controls
      socket.on('toggle-audio', this.handleToggleAudio.bind(this, socket));
      socket.on('toggle-video', this.handleToggleVideo.bind(this, socket));
      socket.on('toggle-screen-share', this.handleToggleScreenShare.bind(this, socket));
      
      // Handle chat messages
      socket.on('chat-message', this.handleChatMessage.bind(this, socket));
      
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

  async storeSocketSession(socketId, user) {
    try {
      await this.redis.setEx(
        `socket:${socketId}`,
        3600, // 1 hour expiry
        JSON.stringify({
          userId: user.userId,
          username: user.username,
          email: user.email,
          connectedAt: new Date().toISOString()
        })
      );
    } catch (error) {
      console.error('Error storing socket session:', error);
    }
  }

  async handleJoinRoom(socket, data) {
    try {
      const { roomId } = data;
      const userId = socket.user.userId;

      // Verify room exists and user can join
      const room = await Room.findById(roomId);
      if (!room) {
        socket.emit('error', { message: 'Room not found' });
        return;
      }

      // Add participant to room in database
      await Room.addParticipant(roomId, userId);

      // Join socket room
      socket.join(roomId);

      // Track room membership
      if (!this.rooms.has(roomId)) {
        this.rooms.set(roomId, new Set());
      }
      this.rooms.get(roomId).add(socket.id);

      // Get current participants
      const participants = await Room.getParticipants(roomId);
      const socketParticipants = Array.from(this.rooms.get(roomId) || [])
        .map(socketId => this.socketUsers.get(socketId))
        .filter(Boolean);

      // Notify room about new participant
      socket.to(roomId).emit('user-joined', {
        user: socket.user,
        participants: socketParticipants
      });

      // Send current participants to new user
      socket.emit('room-joined', {
        room,
        participants: socketParticipants
      });

      console.log(`👥 User ${socket.user.username} joined room ${roomId}`);
    } catch (error) {
      console.error('Error joining room:', error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  }

  async handleLeaveRoom(socket, data) {
    try {
      const { roomId } = data;
      const userId = socket.user.userId;

      await this.leaveRoom(socket, roomId, userId);
    } catch (error) {
      console.error('Error leaving room:', error);
    }
  }

  async leaveRoom(socket, roomId, userId) {
    // Remove from socket room
    socket.leave(roomId);

    // Remove from room tracking
    if (this.rooms.has(roomId)) {
      this.rooms.get(roomId).delete(socket.id);
      
      // Clean up empty room
      if (this.rooms.get(roomId).size === 0) {
        this.rooms.delete(roomId);
      }
    }

    // Remove participant from database
    await Room.removeParticipant(roomId, userId);

    // Notify other participants
    socket.to(roomId).emit('user-left', {
      user: socket.user
    });

    console.log(`👋 User ${socket.user.username} left room ${roomId}`);
  }

  handleOffer(socket, data) {
    const { roomId, targetUserId, offer } = data;
    
    // Send offer to specific user
    const targetSockets = this.userSockets.get(targetUserId);
    if (targetSockets) {
      targetSockets.forEach(socketId => {
        this.io.to(socketId).emit('offer', {
          from: socket.user.userId,
          fromUser: socket.user,
          offer
        });
      });
    }
  }

  handleAnswer(socket, data) {
    const { targetUserId, answer } = data;
    
    // Send answer to specific user
    const targetSockets = this.userSockets.get(targetUserId);
    if (targetSockets) {
      targetSockets.forEach(socketId => {
        this.io.to(socketId).emit('answer', {
          from: socket.user.userId,
          fromUser: socket.user,
          answer
        });
      });
    }
  }

  handleIceCandidate(socket, data) {
    const { targetUserId, candidate } = data;
    
    // Send ICE candidate to specific user
    const targetSockets = this.userSockets.get(targetUserId);
    if (targetSockets) {
      targetSockets.forEach(socketId => {
        this.io.to(socketId).emit('ice-candidate', {
          from: socket.user.userId,
          fromUser: socket.user,
          candidate
        });
      });
    }
  }

  handleToggleAudio(socket, data) {
    const { roomId, isEnabled } = data;
    
    socket.to(roomId).emit('user-audio-toggle', {
      userId: socket.user.userId,
      isEnabled
    });
  }

  handleToggleVideo(socket, data) {
    const { roomId, isEnabled } = data;
    
    socket.to(roomId).emit('user-video-toggle', {
      userId: socket.user.userId,
      isEnabled
    });
  }

  handleToggleScreenShare(socket, data) {
    const { roomId, isEnabled } = data;
    
    socket.to(roomId).emit('user-screen-share-toggle', {
      userId: socket.user.userId,
      isEnabled
    });
  }

  handleChatMessage(socket, data) {
    const { roomId, message } = data;
    
    const chatMessage = {
      id: Date.now().toString(),
      message,
      user: socket.user,
      timestamp: new Date().toISOString()
    };
    
    // Send to all users in room including sender
    this.io.to(roomId).emit('chat-message', chatMessage);
  }

  async handleDisconnect(socket) {
    try {
      const user = socket.user;
      console.log(`❌ User disconnected: ${user.username} (${socket.id})`);

      // Remove from user sockets map
      if (this.userSockets.has(user.userId)) {
        this.userSockets.get(user.userId).delete(socket.id);
        
        // Clean up if no more sockets for this user
        if (this.userSockets.get(user.userId).size === 0) {
          this.userSockets.delete(user.userId);
        }
      }

      // Leave all rooms and update database
      for (const [roomId, socketIds] of this.rooms.entries()) {
        if (socketIds.has(socket.id)) {
          await this.leaveRoom(socket, roomId, user.userId);
        }
      }

      // Remove socket-user mapping
      this.socketUsers.delete(socket.id);

      // Clean up Redis session
      await this.redis.del(`socket:${socket.id}`);
    } catch (error) {
      console.error('Error handling disconnect:', error);
    }
  }

  // Utility method to get room info
  getRoomInfo(roomId) {
    const socketIds = this.rooms.get(roomId) || new Set();
    const participants = Array.from(socketIds)
      .map(socketId => this.socketUsers.get(socketId))
      .filter(Boolean);
    
    return {
      participantCount: participants.length,
      participants
    };
  }

  // Method to forcefully remove user from room (when room is deleted)
  async removeUserFromRoom(userId, roomId) {
    const userSockets = this.userSockets.get(userId);
    if (userSockets) {
      for (const socketId of userSockets) {
        const socket = this.io.sockets.sockets.get(socketId);
        if (socket) {
          await this.leaveRoom(socket, roomId, userId);
          socket.emit('room-deleted', { roomId });
        }
      }
    }
  }
}

module.exports = SocketManager;
