const Joi = require('joi');
const Room = require('../models/Room');

// Validation schemas
const createRoomSchema = Joi.object({
  title: Joi.string().min(1).max(255).required(),
  description: Joi.string().max(1000).allow(''),
  maxParticipants: Joi.number().integer().min(2).max(50).default(10)
});

const updateRoomSchema = Joi.object({
  title: Joi.string().min(1).max(255),
  description: Joi.string().max(1000).allow('')
}).min(1);

class RoomController {
  static async createRoom(req, res) {
    try {
      // Validate input
      const { error, value } = createRoomSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.details[0].message
        });
      }

      const { title, description, maxParticipants } = value;
      const createdBy = req.user.userId;

      // Create room
      const roomId = await Room.create({
        title,
        description,
        createdBy,
        maxParticipants
      });

      res.status(201).json({
        success: true,
        message: 'Room created successfully',
        data: {
          roomId,
          title,
          description,
          maxParticipants
        }
      });
    } catch (error) {
      console.error('Create room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getRooms(req, res) {
    try {
      const userId = req.user.userId;
      const rooms = await Room.findByUser(userId);

      res.json({
        success: true,
        data: { rooms }
      });
    } catch (error) {
      console.error('Get rooms error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async getRoom(req, res) {
    try {
      const { roomId } = req.params;
      const room = await Room.findById(roomId);

      if (!room) {
        return res.status(404).json({
          success: false,
          message: 'Room not found'
        });
      }

      const participants = await Room.getParticipants(roomId);

      res.json({
        success: true,
        data: {
          room: {
            ...room,
            participants
          }
        }
      });
    } catch (error) {
      console.error('Get room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async updateRoom(req, res) {
    try {
      const { roomId } = req.params;
      const userId = req.user.userId;

      // Validate input
      const { error, value } = updateRoomSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.details[0].message
        });
      }

      // Check if room exists and user owns it
      const room = await Room.findById(roomId);
      if (!room) {
        return res.status(404).json({
          success: false,
          message: 'Room not found'
        });
      }

      if (room.created_by !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You can only update your own rooms'
        });
      }

      // Update room
      const updated = await Room.update(roomId, value);
      if (!updated) {
        return res.status(400).json({
          success: false,
          message: 'Failed to update room'
        });
      }

      res.json({
        success: true,
        message: 'Room updated successfully'
      });
    } catch (error) {
      console.error('Update room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async deleteRoom(req, res) {
    try {
      const { roomId } = req.params;
      const userId = req.user.userId;

      // Delete room (this will also check ownership)
      const deleted = await Room.delete(roomId, userId);
      if (!deleted) {
        return res.status(404).json({
          success: false,
          message: 'Room not found or you do not have permission to delete it'
        });
      }

      res.json({
        success: true,
        message: 'Room deleted successfully'
      });
    } catch (error) {
      console.error('Delete room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async joinRoom(req, res) {
    try {
      const { roomId } = req.params;
      const userId = req.user.userId;

      // Check if room exists
      const room = await Room.findById(roomId);
      if (!room) {
        return res.status(404).json({
          success: false,
          message: 'Room not found'
        });
      }

      // Check current participant count
      const participants = await Room.getParticipants(roomId);
      if (participants.length >= room.max_participants) {
        return res.status(400).json({
          success: false,
          message: 'Room is full'
        });
      }

      // Add participant
      const added = await Room.addParticipant(roomId, userId);
      if (!added) {
        return res.status(400).json({
          success: false,
          message: 'Failed to join room'
        });
      }

      res.json({
        success: true,
        message: 'Joined room successfully',
        data: { room }
      });
    } catch (error) {
      console.error('Join room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async leaveRoom(req, res) {
    try {
      const { roomId } = req.params;
      const userId = req.user.userId;

      // Remove participant
      const removed = await Room.removeParticipant(roomId, userId);
      if (!removed) {
        return res.status(400).json({
          success: false,
          message: 'You are not in this room'
        });
      }

      res.json({
        success: true,
        message: 'Left room successfully'
      });
    } catch (error) {
      console.error('Leave room error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = RoomController;
