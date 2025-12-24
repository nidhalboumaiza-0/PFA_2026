import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getConfig } from '../../../../shared/index.js';

let io = null;

/**
 * Initialize Socket.IO server
 * @param {object} httpServer - HTTP server instance
 * @returns {object} Socket.IO instance
 */
export const initializeSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: getConfig('FRONTEND_URL', 'http://localhost:3000'),
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // JWT authentication middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    try {
      const decoded = jwt.verify(token, getConfig('JWT_SECRET'));
      socket.userId = decoded.userId;
      socket.userType = decoded.userType;
      next();
    } catch (error) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log(`✅ Socket.IO: User ${socket.userId} connected`);

    // Join user's personal room
    socket.join(socket.userId);

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`❌ Socket.IO: User ${socket.userId} disconnected`);
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error(`Socket.IO error for user ${socket.userId}:`, error);
    });
  });

  console.log('✅ Socket.IO server initialized');

  return io;
};

/**
 * Get Socket.IO instance
 * @returns {object} Socket.IO instance
 */
export const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

/**
 * Emit notification to specific user
 * @param {string} userId - User ID
 * @param {object} notification - Notification data
 */
export const emitNotificationToUser = (userId, notification) => {
  if (io) {
    io.to(userId.toString()).emit('new_notification', notification);
  }
};
