import express from 'express';
import {
  setAvailability,
  bulkSetAvailability,
  getDoctorAvailability,
  viewDoctorAvailability,
  requestAppointment,
  getAppointmentRequests,
  confirmAppointment,
  rejectAppointment,
  cancelAppointment,
  getAppointmentDetails,
  getPatientAppointments,
  getDoctorAppointments,
  completeAppointment,
  referralBooking,
  getAppointmentStatistics,
  checkAppointmentRelationship,
  rescheduleAppointment,
  requestReschedule,
  approveReschedule,
  rejectReschedule,
  addDocumentToAppointment,
  removeDocumentFromAppointment,
  getAppointmentDocuments
} from '../controllers/appointmentController.js';
import { auth, authorize } from '../../../../shared/index.js';
import {
  validateSetAvailability,
  validateBulkSetAvailability,
  validateRequestAppointment,
  validateConfirmAppointment,
  validateRejectAppointment,
  validateCancelAppointment,
  validateReferralBooking
} from '../validators/appointmentValidator.js';

const router = express.Router();

// ============================
// INTERNAL SERVICE ROUTES (no auth - service-to-service)
// ============================

// Check appointment relationship between patient and doctor
// Used by messaging service to verify messaging permissions
router.get('/check-relationship', checkAppointmentRelationship);

// ============================
// DOCTOR ROUTES
// ============================

// Doctor: Set availability
router.post(
  '/doctor/availability',
  auth,
  authorize('doctor'),
  validateSetAvailability,
  setAvailability
);

// Doctor: Bulk set availability (for templates)
router.post(
  '/doctor/availability/bulk',
  auth,
  authorize('doctor'),
  validateBulkSetAvailability,
  bulkSetAvailability
);

// Doctor: Get my availability
router.get(
  '/doctor/availability',
  auth,
  authorize('doctor'),
  getDoctorAvailability
);

// Doctor: Get appointment requests
router.get(
  '/doctor/requests',
  auth,
  authorize('doctor'),
  getAppointmentRequests
);

// Doctor: Confirm appointment
router.put(
  '/:appointmentId/confirm',
  auth,
  authorize('doctor'),
  validateConfirmAppointment,
  confirmAppointment
);

// Doctor: Reject appointment
router.put(
  '/:appointmentId/reject',
  auth,
  authorize('doctor'),
  validateRejectAppointment,
  rejectAppointment
);

// Doctor: Reschedule appointment (direct, no patient approval needed)
router.put(
  '/:appointmentId/reschedule',
  auth,
  authorize('doctor'),
  rescheduleAppointment
);

// Doctor: Approve patient's reschedule request
router.put(
  '/:appointmentId/approve-reschedule',
  auth,
  authorize('doctor'),
  approveReschedule
);

// Doctor: Reject patient's reschedule request
router.put(
  '/:appointmentId/reject-reschedule',
  auth,
  authorize('doctor'),
  rejectReschedule
);

// Doctor: Complete appointment
router.put(
  '/:appointmentId/complete',
  auth,
  authorize('doctor'),
  completeAppointment
);

// Doctor: Get my appointments
router.get(
  '/doctor/my-appointments',
  auth,
  authorize('doctor'),
  getDoctorAppointments
);

// Doctor: Get appointment statistics
router.get(
  '/doctor/statistics',
  auth,
  authorize('doctor'),
  getAppointmentStatistics
);

// Doctor: Book referral appointment
router.post(
  '/referral-booking',
  auth,
  authorize('doctor'),
  validateReferralBooking,
  referralBooking
);

// ============================
// PATIENT ROUTES
// ============================

// Patient: View doctor availability (public)
router.get(
  '/doctors/:doctorId/availability',
  auth,
  authorize('patient'),
  viewDoctorAvailability
);

// Patient: Request appointment
router.post(
  '/request',
  auth,
  authorize('patient'),
  validateRequestAppointment,
  requestAppointment
);

// Patient: Cancel appointment
router.put(
  '/:appointmentId/cancel',
  auth,
  authorize('patient'),
  validateCancelAppointment,
  cancelAppointment
);

// Patient: Request reschedule (requires doctor approval)
router.put(
  '/:appointmentId/request-reschedule',
  auth,
  authorize('patient'),
  requestReschedule
);

// Patient: Get my appointments
router.get(
  '/patient/my-appointments',
  auth,
  authorize('patient'),
  getPatientAppointments
);

// ============================
// SHARED ROUTES
// ============================

// Get appointment details (both patient & doctor)
router.get(
  '/:appointmentId',
  auth,
  getAppointmentDetails
);

// ============================
// DOCUMENT ROUTES
// ============================

// Get appointment documents (both patient & doctor)
router.get(
  '/:appointmentId/documents',
  auth,
  getAppointmentDocuments
);

// Patient: Add document to appointment
router.post(
  '/:appointmentId/documents',
  auth,
  authorize('patient'),
  addDocumentToAppointment
);

// Patient: Remove document from appointment
router.delete(
  '/:appointmentId/documents/:documentId',
  auth,
  authorize('patient'),
  removeDocumentFromAppointment
);

export default router;
