const express = require('express');
const RoomController = require('../controllers/roomController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All room routes require authentication
router.use(authMiddleware);

router.post('/', RoomController.createRoom);
router.get('/', RoomController.getRooms);
router.get('/:roomId', RoomController.getRoom);
router.put('/:roomId', RoomController.updateRoom);
router.delete('/:roomId', RoomController.deleteRoom);
router.post('/:roomId/join', RoomController.joinRoom);
router.post('/:roomId/leave', RoomController.leaveRoom);

module.exports = router;
