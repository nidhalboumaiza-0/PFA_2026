import express from 'express';
import {
  createReferral,
  getReferralById,
  searchSpecialistsForReferral,
  bookAppointmentForReferral,
  getReceivedReferrals,
  getSentReferrals,
  acceptReferral,
  rejectReferral,
  completeReferral,
  cancelReferral,
  getMyReferrals,
  getReferralStatistics
} from '../controllers/referralController.js';
import { auth, authorize } from '../../../../shared/index.js';
import {
  validateCreateReferral,
  validateBookAppointment,
  validateAcceptReferral,
  validateRejectReferral,
  validateCompleteReferral,
  validateCancelReferral,
  validateSearchSpecialists,
  validateGetReceivedReferrals,
  validateGetSentReferrals
} from '../validators/referralValidator.js';

const router = express.Router();

// ============================
// DOCTOR ROUTES - CREATE & MANAGE REFERRALS
// ============================

// Create referral
router.post(
  '/',
  auth,
  authorize('doctor'),
  validateCreateReferral,
  createReferral
);

// Search specialists for referral
router.get(
  '/search-specialists',
  auth,
  authorize('doctor'),
  validateSearchSpecialists,
  searchSpecialistsForReferral
);

// Book appointment for referral
router.post(
  '/:referralId/book-appointment',
  auth,
  authorize('doctor'),
  validateBookAppointment,
  bookAppointmentForReferral
);

// Get sent referrals (referring doctor)
router.get(
  '/sent',
  auth,
  authorize('doctor'),
  validateGetSentReferrals,
  getSentReferrals
);

// Get received referrals (target doctor)
router.get(
  '/received',
  auth,
  authorize('doctor'),
  validateGetReceivedReferrals,
  getReceivedReferrals
);

// Accept referral (target doctor)
router.put(
  '/:referralId/accept',
  auth,
  authorize('doctor'),
  validateAcceptReferral,
  acceptReferral
);

// Reject referral (target doctor)
router.put(
  '/:referralId/reject',
  auth,
  authorize('doctor'),
  validateRejectReferral,
  rejectReferral
);

// Complete referral (target doctor)
router.put(
  '/:referralId/complete',
  auth,
  authorize('doctor'),
  validateCompleteReferral,
  completeReferral
);

// Get referral statistics
router.get(
  '/statistics',
  auth,
  authorize('doctor', 'admin'),
  getReferralStatistics
);

// ============================
// PATIENT ROUTES
// ============================

// Get my referrals (patient)
router.get(
  '/my-referrals',
  auth,
  authorize('patient'),
  getMyReferrals
);

// ============================
// SHARED ROUTES
// ============================

// Cancel referral (referring doctor or patient)
router.put(
  '/:referralId/cancel',
  auth,
  validateCancelReferral,
  cancelReferral
);

// Get referral details (referring doctor, target doctor, or patient)
router.get(
  '/:referralId',
  auth,
  getReferralById
);

export default router;
