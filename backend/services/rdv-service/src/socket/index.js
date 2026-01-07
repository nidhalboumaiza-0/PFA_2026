import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getConfig } from '../../../../shared/index.js';

let io = null;

/**
 * Initialize Socket.IO for real-time admin appointment management
 */
export const initializeSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    path: '/rdv-socket'
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
      console.error('[RdvSocket] Auth error:', error.message);
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`[RdvSocket] User connected: ${socket.user.email} (${socket.user.role})`);

    // Only admins can join the admin room
    socket.on('join_admin_room', () => {
      if (socket.user.role !== 'admin') {
        socket.emit('error', { message: 'Admin access required' });
        return;
      }

      socket.join('admin_appointments');
      console.log(`[RdvSocket] Admin ${socket.user.email} joined admin_appointments room`);
      
      socket.emit('joined_admin_room', {
        message: 'Successfully joined admin appointments room',
        timestamp: new Date().toISOString()
      });
    });

    // Subscribe to real-time appointment updates
    socket.on('subscribe_appointment_updates', () => {
      if (socket.user.role !== 'admin') {
        socket.emit('error', { message: 'Admin access required' });
        return;
      }

      socket.join('admin_appointments');
      socket.emit('subscribed', {
        channel: 'appointment_updates',
        message: 'Subscribed to appointment updates'
      });
    });

    // Doctors can subscribe to their own appointments
    socket.on('subscribe_doctor_appointments', () => {
      if (socket.user.role !== 'doctor') {
        socket.emit('error', { message: 'Doctor access required' });
        return;
      }

      const room = `doctor_${socket.user.profileId}`;
      socket.join(room);
      socket.emit('subscribed', {
        channel: 'doctor_appointments',
        message: 'Subscribed to your appointment updates'
      });
    });

    // Patients can subscribe to their own appointments
    socket.on('subscribe_patient_appointments', () => {
      if (socket.user.role !== 'patient') {
        socket.emit('error', { message: 'Patient access required' });
        return;
      }

      const room = `patient_${socket.user.profileId}`;
      socket.join(room);
      socket.emit('subscribed', {
        channel: 'patient_appointments',
        message: 'Subscribed to your appointment updates'
      });
    });

    // Unsubscribe from updates
    socket.on('unsubscribe_appointment_updates', () => {
      socket.leave('admin_appointments');
      socket.emit('unsubscribed', {
        channel: 'appointment_updates',
        message: 'Unsubscribed from appointment updates'
      });
    });

    // Request current online admin count
    socket.on('get_admin_count', async () => {
      const adminRoom = io.sockets.adapter.rooms.get('admin_appointments');
      const count = adminRoom ? adminRoom.size : 0;
      socket.emit('admin_count', { count });
    });

    socket.on('disconnect', () => {
      console.log(`[RdvSocket] User disconnected: ${socket.user.email}`);
    });
  });

  console.log('[RdvSocket] Socket.IO initialized for rdv-service');
  return io;
};

/**
 * Get the Socket.IO instance
 */
export const getIO = () => io;

/**
 * Emit a new appointment event to admin dashboard
 */
export const emitNewAppointment = (appointmentData) => {
  if (io) {
    // Notify admins
    io.to('admin_appointments').emit('new_appointment', {
      ...appointmentData,
      timestamp: new Date().toISOString()
    });

    // Notify the doctor
    if (appointmentData.doctorId) {
      io.to(`doctor_${appointmentData.doctorId}`).emit('new_appointment', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }
  }
};

/**
 * Emit appointment status changed event
 */
export const emitAppointmentStatusChanged = (appointmentData) => {
  if (io) {
    // Notify admins
    io.to('admin_appointments').emit('appointment_status_changed', {
      ...appointmentData,
      timestamp: new Date().toISOString()
    });

    // Notify the doctor
    if (appointmentData.doctorId) {
      io.to(`doctor_${appointmentData.doctorId}`).emit('appointment_status_changed', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }

    // Notify the patient
    if (appointmentData.patientId) {
      io.to(`patient_${appointmentData.patientId}`).emit('appointment_status_changed', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }
  }
};

/**
 * Emit appointment confirmed event
 */
export const emitAppointmentConfirmed = (appointmentData) => {
  if (io) {
    io.to('admin_appointments').emit('appointment_confirmed', {
      ...appointmentData,
      timestamp: new Date().toISOString()
    });

    if (appointmentData.patientId) {
      io.to(`patient_${appointmentData.patientId}`).emit('appointment_confirmed', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }
  }
};

/**
 * Emit appointment cancelled event
 */
export const emitAppointmentCancelled = (appointmentData) => {
  if (io) {
    io.to('admin_appointments').emit('appointment_cancelled', {
      ...appointmentData,
      timestamp: new Date().toISOString()
    });

    if (appointmentData.doctorId) {
      io.to(`doctor_${appointmentData.doctorId}`).emit('appointment_cancelled', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }

    if (appointmentData.patientId) {
      io.to(`patient_${appointmentData.patientId}`).emit('appointment_cancelled', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }
  }
};

/**
 * Emit appointment rescheduled event
 */
export const emitAppointmentRescheduled = (appointmentData) => {
  if (io) {
    io.to('admin_appointments').emit('appointment_rescheduled', {
      ...appointmentData,
      timestamp: new Date().toISOString()
    });

    if (appointmentData.doctorId) {
      io.to(`doctor_${appointmentData.doctorId}`).emit('appointment_rescheduled', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }

    if (appointmentData.patientId) {
      io.to(`patient_${appointmentData.patientId}`).emit('appointment_rescheduled', {
        ...appointmentData,
        timestamp: new Date().toISOString()
      });
    }
  }
};

/**
 * Emit stats update (called periodically or on significant changes)
 */
export const emitStatsUpdate = async (stats) => {
  if (io) {
    io.to('admin_appointments').emit('stats_updated', {
      ...stats,
      timestamp: new Date().toISOString()
    });
  }
};

export default { 
  initializeSocket, 
  getIO, 
  emitNewAppointment, 
  emitAppointmentStatusChanged,
  emitAppointmentConfirmed,
  emitAppointmentCancelled,
  emitAppointmentRescheduled,
  emitStatsUpdate 
};
