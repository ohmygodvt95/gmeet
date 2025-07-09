const mysql = require('mysql2/promise');
const Redis = require('redis');
const config = require('./index');

class Database {
  constructor() {
    this.mysql = null;
    this.redis = null;
  }

  async connectMySQL() {
    try {
      this.mysql = await mysql.createConnection({
        host: config.database.host,
        port: config.database.port,
        user: config.database.user,
        password: config.database.password,
        database: config.database.database,
        reconnect: true,
      });
      
      console.log('✅ MySQL connected successfully');
      return this.mysql;
    } catch (error) {
      console.error('❌ MySQL connection failed:', error.message);
      throw error;
    }
  }

  async connectRedis() {
    try {
      this.redis = Redis.createClient({
        host: config.redis.host,
        port: config.redis.port,
        password: config.redis.password,
      });

      this.redis.on('error', (err) => {
        console.error('❌ Redis Client Error:', err);
      });

      this.redis.on('connect', () => {
        console.log('✅ Redis connected successfully');
      });

      await this.redis.connect();
      return this.redis;
    } catch (error) {
      console.error('❌ Redis connection failed:', error.message);
      throw error;
    }
  }

  async init() {
    await this.connectMySQL();
    await this.connectRedis();
  }

  getMySQL() {
    return this.mysql;
  }

  getRedis() {
    return this.redis;
  }

  async close() {
    if (this.mysql) {
      await this.mysql.end();
    }
    if (this.redis) {
      await this.redis.quit();
    }
  }
}

module.exports = new Database();
