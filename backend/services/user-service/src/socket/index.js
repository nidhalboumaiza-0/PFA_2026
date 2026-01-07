import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getConfig } from '../../../../shared/index.js';

let io = null;

/**
 * Initialize Socket.IO for real-time admin user management
 */
export const initializeSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    path: '/user-socket'
  });

  // Authentication middleware
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token || 
                    socket.handshake.headers?.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const jwtSecret = getConfig('JWT_SECRET', 'esante-secret-key-dev-2024');
      const decoded = jwt.verify(token, jwtSecret);
      
      socket.user = decoded;
      next();
    } catch (error) {
      console.error('[UserSocket] Auth error:', error.message);
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`[UserSocket] User connected: ${socket.user.email} (${socket.user.role})`);

    // Only admins can join the admin room
    socket.on('join_admin_room', () => {
      if (socket.user.role !== 'admin') {
        socket.emit('error', { message: 'Admin access required' });
        return;
      }

      socket.join('admin_users');
      console.log(`[UserSocket] Admin ${socket.user.email} joined admin_users room`);
      
      socket.emit('joined_admin_room', {
        message: 'Successfully joined admin users room',
        timestamp: new Date().toISOString()
      });
    });

    // Subscribe to real-time user updates
    socket.on('subscribe_user_updates', () => {
      if (socket.user.role !== 'admin') {
        socket.emit('error', { message: 'Admin access required' });
        return;
      }

      socket.join('admin_users');
      socket.emit('subscribed', {
        channel: 'user_updates',
        message: 'Subscribed to user updates'
      });
    });

    // Unsubscribe from updates
    socket.on('unsubscribe_user_updates', () => {
      socket.leave('admin_users');
      socket.emit('unsubscribed', {
        channel: 'user_updates',
        message: 'Unsubscribed from user updates'
      });
    });

    // Request current online admin count
    socket.on('get_admin_count', async () => {
      const adminRoom = io.sockets.adapter.rooms.get('admin_users');
      const count = adminRoom ? adminRoom.size : 0;
      socket.emit('admin_count', { count });
    });

    socket.on('disconnect', () => {
      console.log(`[UserSocket] User disconnected: ${socket.user.email}`);
    });
  });

  console.log('[UserSocket] Socket.IO initialized for user-service');
  return io;
};

/**
 * Get the Socket.IO instance
 */
export const getIO = () => io;

/**
 * Emit a new user registration event to admin dashboard
 */
export const emitNewUserRegistration = (userData) => {
  if (io) {
    io.to('admin_users').emit('new_user_registered', {
      ...userData,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Emit user profile updated event
 */
export const emitUserProfileUpdated = (userData) => {
  if (io) {
    io.to('admin_users').emit('user_profile_updated', {
      ...userData,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Emit stats update (called periodically or on significant changes)
 */
export const emitStatsUpdate = async (stats) => {
  if (io) {
    io.to('admin_users').emit('stats_updated', {
      ...stats,
      timestamp: new Date().toISOString()
    });
  }
};

export default { initializeSocket, getIO, emitNewUserRegistration, emitUserProfileUpdated, emitStatsUpdate };
