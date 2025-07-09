require('dotenv').config();

module.exports = {
  port: process.env.BACKEND_PORT || 3001,
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:3000',
  
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'sail',
    password: process.env.DB_PASSWORD || 'password',
    database: process.env.DB_NAME || 'gmeeting',
  },
  
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
  },
  
  jwt: {
    secret: process.env.JWT_SECRET || 'fallback-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  
  webrtc: {
    turnServerUrl: process.env.TURN_SERVER_URL || 'stun:stun.l.google.com:19302',
  },
};
