import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getConfig } from '../../../../shared/index.js';

let io = null;

/**
 * Initialize Socket.IO for real-time audit monitoring
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
    const token =
      socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    try {
      const decoded = jwt.verify(token, getConfig('JWT_SECRET'));
      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      next();
    } catch (error) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log(`✅ Socket.IO: User ${socket.userId} (${socket.userRole}) connected`);

    // Only admins can monitor audit stream
    if (socket.userRole === 'admin') {
      // Join admin monitoring room
      socket.join('audit_monitor');
      console.log(`✅ Admin ${socket.userId} joined audit monitoring room`);

      // Handle subscription to audit stream
      socket.on('subscribe_audit', () => {
        console.log(`Admin ${socket.userId} subscribed to audit stream`);
        socket.emit('audit_subscribed', {
          message: 'Successfully subscribed to audit stream',
          timestamp: new Date(),
        });
      });

      // Handle unsubscribe
      socket.on('unsubscribe_audit', () => {
        console.log(`Admin ${socket.userId} unsubscribed from audit stream`);
        socket.leave('audit_monitor');
      });
    } else {
      // Non-admin users cannot access audit monitoring
      socket.emit('error', {
        message: 'Access denied: Admin privileges required for audit monitoring',
      });
      socket.disconnect(true);
    }

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`❌ Socket.IO: User ${socket.userId} disconnected from audit monitoring`);
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error(`Socket.IO error for user ${socket.userId}:`, error);
    });
  });

  console.log('✅ Socket.IO server initialized for audit monitoring');

  return io;
};

/**
 * Get Socket.IO instance
 */
export const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

/**
 * Emit critical event to admin dashboard
 */
export const emitCriticalEvent = (auditLog) => {
  if (io) {
    io.to('audit_monitor').emit('critical_event', {
      id: auditLog._id,
      action: auditLog.action,
      actionCategory: auditLog.actionCategory,
      performedBy: {
        id: auditLog.performedBy,
        name: auditLog.performedByName,
        type: auditLog.performedByType,
      },
      description: auditLog.description,
      severity: auditLog.severity,
      timestamp: auditLog.timestamp,
      ipAddress: auditLog.ipAddress,
      requiresReview: auditLog.requiresReview,
    });
    console.log(`✅ Critical audit event emitted: ${auditLog.action}`);
  }
};

/**
 * Emit security alert to admin dashboard
 */
export const emitSecurityAlert = (auditLog) => {
  if (io) {
    io.to('audit_monitor').emit('security_alert', {
      id: auditLog._id,
      action: auditLog.action,
      description: auditLog.description,
      severity: auditLog.severity,
      performedBy: auditLog.performedByName,
      ipAddress: auditLog.ipAddress,
      timestamp: auditLog.timestamp,
    });
    console.log(`✅ Security alert emitted: ${auditLog.action}`);
  }
};
