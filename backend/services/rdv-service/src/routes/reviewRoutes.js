import express from 'express';
import {
    submitReview,
    getDoctorReviews,
    getAppointmentReview,
    updateReview,
    deleteReview
} from '../controllers/reviewController.js';
import { auth, authorize } from '../../../../shared/index.js';

const router = express.Router();

// ============================
// PUBLIC ROUTES
// ============================

// Get all reviews for a doctor (public - anyone can see reviews)
router.get('/doctors/:doctorId', getDoctorReviews);

// ============================
// PATIENT ROUTES
// ============================

// Patient: Submit a review for a completed appointment
router.post(
    '/appointments/:appointmentId',
    auth,
    authorize('patient'),
    submitReview
);

// Get review for a specific appointment (patient or doctor)
router.get(
    '/appointments/:appointmentId',
    auth,
    authorize('patient', 'doctor'),
    getAppointmentReview
);

// Patient: Update a review (within 24 hours)
router.put(
    '/:reviewId',
    auth,
    authorize('patient'),
    updateReview
);

// Patient: Delete a review (within 24 hours)
router.delete(
    '/:reviewId',
    auth,
    authorize('patient'),
    deleteReview
);

export default router;
