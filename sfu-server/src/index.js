const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');

const config = require('./config');
const MediaSoupManager = require('./mediasoupManager');
const SFUSocketManager = require('./sfuSocketManager');

class SFUServer {
  constructor() {
    this.app = express();
    this.server = http.createServer(this.app);
    this.io = socketIo(this.server, {
      cors: {
        origin: "*", // Allow all origins for SFU server
        methods: ["GET", "POST"],
      }
    });
    
    this.mediaSoupManager = new MediaSoupManager();
    this.sfuSocketManager = null;
    
    this.setupMiddleware();
    this.setupRoutes();
  }

  setupMiddleware() {
    // CORS
    this.app.use(cors());
    
    // Body parsing
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
  }

  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'OK',
        server: 'SFU Server',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      });
    });

    // Stats endpoint
    this.app.get('/stats', (req, res) => {
      const stats = this.sfuSocketManager ? this.sfuSocketManager.getStats() : null;
      res.json({
        success: true,
        data: stats,
      });
    });

    // Room stats endpoint
    this.app.get('/rooms/:roomId/stats', (req, res) => {
      const { roomId } = req.params;
      const roomStats = this.sfuSocketManager ? this.sfuSocketManager.getRoomStats(roomId) : null;
      res.json({
        success: true,
        data: roomStats,
      });
    });

    // 404 handler
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        message: 'Endpoint not found',
      });
    });

    // Error handler
    this.app.use((error, req, res, next) => {
      console.error('SFU Server error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    });
  }

  async start() {
    try {
      // Initialize MediaSoup
      await this.mediaSoupManager.init();
      
      // Initialize Socket.IO manager
      this.sfuSocketManager = new SFUSocketManager(this.io, this.mediaSoupManager);
      
      // Start server
      this.server.listen(config.port, () => {
        console.log(`🚀 SFU Server running on port ${config.port}`);
        console.log(`📡 MediaSoup SFU ready for video conferencing`);
        console.log(`🔧 Backend URL: ${config.backendUrl}`);
      });

      // Graceful shutdown
      process.on('SIGTERM', this.shutdown.bind(this));
      process.on('SIGINT', this.shutdown.bind(this));

    } catch (error) {
      console.error('❌ Failed to start SFU server:', error);
      process.exit(1);
    }
  }

  async shutdown() {
    console.log('🛑 Shutting down SFU server...');
    
    this.server.close(() => {
      console.log('✅ SFU HTTP server closed');
    });

    // Close all MediaSoup workers
    if (this.mediaSoupManager.workers) {
      this.mediaSoupManager.workers.forEach(worker => {
        worker.close();
      });
    }

    console.log('✅ MediaSoup workers closed');
    process.exit(0);
  }
}

// Start SFU server
const sfuServer = new SFUServer();
sfuServer.start();

module.exports = SFUServer;
