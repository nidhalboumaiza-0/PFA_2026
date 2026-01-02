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
      origin: '*', // Allow all origins for mobile app support
      methods: ['GET', 'POST'],
      credentials: true,
    },
    // Allow connections from API Gateway proxy
    allowEIO3: true,
    // Connection stability settings
    pingTimeout: 60000,
    pingInterval: 25000,
    transports: ['websocket', 'polling'],
    allowUpgrades: true,
  });

  // JWT authentication middleware
  io.use((socket, next) => {
    // Try to get token from auth object or headers
    const token = socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '') ||
      socket.handshake.query?.token;

    console.log('🔐 Socket.IO auth attempt:', {
      hasAuthToken: !!socket.handshake.auth?.token,
      hasAuthHeader: !!socket.handshake.headers?.authorization,
      hasQueryToken: !!socket.handshake.query?.token,
    });

    if (!token) {
      console.log('❌ Socket.IO: No token provided');
      return next(new Error('Authentication error: Token missing'));
    }

    try {
      const decoded = jwt.verify(token, getConfig('JWT_SECRET'));
      // Support both 'id' and 'userId' for backwards compatibility
      socket.userId = decoded.id || decoded.userId;
      socket.profileId = decoded.profileId; // Profile ID for doctors/patients
      socket.userType = decoded.role || decoded.userType;
      console.log(`✅ Socket.IO: Token verified for user ${socket.userId} (profileId: ${socket.profileId}, role: ${socket.userType})`);
      next();
    } catch (error) {
      console.log('❌ Socket.IO: Token verification failed:', error.message);
      next(new Error('Authentication error: Invalid token'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log(`✅ Socket.IO: User ${socket.userId} connected (profileId: ${socket.profileId})`);

    // Join user's personal room (auth user ID)
    socket.join(socket.userId);
    
    // Also join profile ID room if exists (for appointment notifications)
    // Appointments store doctorId/patientId as profile IDs, not auth user IDs
    if (socket.profileId) {
      socket.join(socket.profileId);
      console.log(`📡 Socket.IO: User also joined profile room ${socket.profileId}`);
    }

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
    // Emit generic notification event
    io.to(userId.toString()).emit('new_notification', notification);

    // Also emit type-specific event for real-time appointment updates
    if (notification.type) {
      const typeEventMap = {
        'appointment_confirmed': 'appointment_confirmed',
        'appointment_rejected': 'appointment_rejected',
        'appointment_cancelled': 'appointment_cancelled',
        'appointment_rescheduled': 'appointment_rescheduled',
        'appointment_completed': 'appointment_completed',
        'appointment_reminder': 'appointment_updated',
        'new_appointment_request': 'new_appointment_request',
        'reschedule_approved': 'appointment_rescheduled',
        'reschedule_rejected': 'appointment_status_changed',
      };

      const specificEvent = typeEventMap[notification.type];
      if (specificEvent) {
        io.to(userId.toString()).emit(specificEvent, {
          appointmentId: notification.actionData?.appointmentId,
          type: notification.type,
          ...notification.actionData,
        });

        // Also emit generic status changed event
        io.to(userId.toString()).emit('appointment_status_changed', {
          appointmentId: notification.actionData?.appointmentId,
          status: notification.type.replace('appointment_', ''),
          ...notification.actionData,
        });
      }
    }
  }
};

/**
 * Emit appointment event to specific user (for real-time updates)
 * @param {string} userId - User ID
 * @param {string} eventType - Event type (appointment_confirmed, etc.)
 * @param {object} data - Event data
 */
export const emitAppointmentEvent = (userId, eventType, data) => {
  if (io) {
    console.log(`📡 Emitting ${eventType} to user ${userId}:`, data);
    io.to(userId.toString()).emit(eventType, data);
    io.to(userId.toString()).emit('appointment_status_changed', {
      ...data,
      eventType,
    });
  }
};

/**
 * Check if user is connected to this notification service's Socket.IO
 * @param {string} userId - User ID
 * @returns {boolean} - True if user has at least one socket connection
 */
export const isUserConnectedLocally = (userId) => {
  if (!io) return false;
  const room = io.sockets.adapter.rooms.get(userId.toString());
  return room && room.size > 0;
};
