const database = require('../config/database');

class User {
  static async create(userData) {
    const mysql = database.getMySQL();
    const { username, email, password, fullName } = userData;
    
    const [result] = await mysql.execute(
      'INSERT INTO users (username, email, password, full_name) VALUES (?, ?, ?, ?)',
      [username, email, password, fullName]
    );
    
    return result.insertId;
  }

  static async findByEmail(email) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    
    return rows[0] || null;
  }

  static async findByUsername(username) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );
    
    return rows[0] || null;
  }

  static async findById(id) {
    const mysql = database.getMySQL();
    const [rows] = await mysql.execute(
      'SELECT id, username, email, full_name, avatar_url, created_at FROM users WHERE id = ?',
      [id]
    );
    
    return rows[0] || null;
  }

  static async update(id, userData) {
    const mysql = database.getMySQL();
    const fields = [];
    const values = [];
    
    if (userData.fullName !== undefined) {
      fields.push('full_name = ?');
      values.push(userData.fullName);
    }
    
    if (userData.avatarUrl !== undefined) {
      fields.push('avatar_url = ?');
      values.push(userData.avatarUrl);
    }
    
    if (fields.length === 0) {
      return false;
    }
    
    values.push(id);
    
    const [result] = await mysql.execute(
      `UPDATE users SET ${fields.join(', ')} WHERE id = ?`,
      values
    );
    
    return result.affectedRows > 0;
  }
}

module.exports = User;
