const database = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Room {
  static async create(roomData) {
    const mysql = database.getMySQL();
    const { title, description, createdBy, maxParticipants = 10 } = roomData;
    const roomId = uuidv4();
    
    const [result] = await mysql.execute(
      'INSERT INTO rooms (id, title, description, created_by, max_participants) VALUES (?, ?, ?, ?, ?)',
      [roomId, title, description, createdBy, maxParticipants]
    );
    
    return roomId;
  }

  static async findById(id) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      `SELECT r.*, u.username as creator_username, u.full_name as creator_name 
       FROM rooms r 
       LEFT JOIN users u ON r.created_by = u.id 
       WHERE r.id = ? AND r.is_active = true`,
      [id]
    );
    
    return rows[0] || null;
  }

  static async findByUser(userId) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      `SELECT r.*, u.username as creator_username, u.full_name as creator_name,
       (SELECT COUNT(*) FROM room_participants rp WHERE rp.room_id = r.id AND rp.is_active = true) as participant_count
       FROM rooms r 
       LEFT JOIN users u ON r.created_by = u.id 
       WHERE r.created_by = ? AND r.is_active = true 
       ORDER BY r.created_at DESC`,
      [userId]
    );
    
    return rows;
  }

  static async update(id, roomData) {
    const mysql = database.getMySQL();
    const { title, description } = roomData;
    
    const [result] = await mysql.execute(
      'UPDATE rooms SET title = ?, description = ? WHERE id = ?',
      [title, description, id]
    );
    
    return result.affectedRows > 0;
  }

  static async delete(id, userId) {
    const mysql = database.getMySQL();
    
    // First check if user owns the room
    const [checkRows] = await mysql.execute(
      'SELECT created_by FROM rooms WHERE id = ? AND is_active = true',
      [id]
    );
    
    if (!checkRows[0] || checkRows[0].created_by !== userId) {
      return false;
    }
    
    // Soft delete the room
    const [result] = await mysql.execute(
      'UPDATE rooms SET is_active = false WHERE id = ?',
      [id]
    );
    
    // Remove all active participants
    await mysql.execute(
      'UPDATE room_participants SET is_active = false, left_at = NOW() WHERE room_id = ? AND is_active = true',
      [id]
    );
    
    return result.affectedRows > 0;
  }

  static async getParticipants(roomId) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      `SELECT rp.*, u.username, u.full_name, u.avatar_url 
       FROM room_participants rp 
       LEFT JOIN users u ON rp.user_id = u.id 
       WHERE rp.room_id = ? AND rp.is_active = true`,
      [roomId]
    );
    
    return rows;
  }

  static async addParticipant(roomId, userId) {
    const mysql = database.getMySQL();
    
    try {
      const [result] = await mysql.execute(
        'INSERT INTO room_participants (room_id, user_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE is_active = true, joined_at = NOW(), left_at = NULL',
        [roomId, userId]
      );
      
      return true;
    } catch (error) {
      console.error('Error adding participant:', error);
      return false;
    }
  }

  static async removeParticipant(roomId, userId) {
    const mysql = database.getMySQL();
    
    const [result] = await mysql.execute(
      'UPDATE room_participants SET is_active = false, left_at = NOW() WHERE room_id = ? AND user_id = ? AND is_active = true',
      [roomId, userId]
    );
    
    return result.affectedRows > 0;
  }
}

module.exports = Room;
