import express from 'express';
import { auth, adminAuth } from '../../../../shared/index.js';
import {
  getAllAppointments,
  getAppointmentById,
  updateAppointmentStatus,
  rescheduleAppointment,
  deleteAppointment,
  getAppointmentStats,
  getRecentActivity,
  getTodayAppointments,
  getPendingRescheduleRequests,
  getAdvancedAnalytics
} from '../controllers/adminAppointmentController.js';

const router = express.Router();

// All admin routes require authentication and admin role
router.use(auth, adminAuth);

// ============================
// STATISTICS & DASHBOARD
// ============================

// Get appointment statistics
router.get('/stats', getAppointmentStats);

// Get advanced analytics (by doctor, patient, region)
router.get('/analytics', getAdvancedAnalytics);

// Get recent activity
router.get('/recent-activity', getRecentActivity);

// Get today's appointments
router.get('/today', getTodayAppointments);

// Get pending reschedule requests
router.get('/reschedule-requests', getPendingRescheduleRequests);

// ============================
// APPOINTMENT MANAGEMENT
// ============================

// Get all appointments with filters
router.get('/appointments', getAllAppointments);

// Get single appointment by ID
router.get('/appointments/:id', getAppointmentById);

// Update appointment status (admin override)
router.put('/appointments/:id/status', updateAppointmentStatus);

// Reschedule appointment (admin override)
router.put('/appointments/:id/reschedule', rescheduleAppointment);

// Delete appointment
router.delete('/appointments/:id', deleteAppointment);

export default router;
