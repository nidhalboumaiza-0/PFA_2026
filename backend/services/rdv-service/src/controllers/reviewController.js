import Review from '../models/Review.js';
import Appointment from '../models/Appointment.js';
import { kafkaProducer, TOPICS, createEvent, sendError, sendSuccess, mongoose } from '../../../../shared/index.js';

/**
 * Patient: Submit a review for a completed appointment
 * POST /api/v1/reviews/appointments/:appointmentId
 */
export const submitReview = async (req, res, next) => {
    try {
        const { appointmentId } = req.params;
        const { rating, comment } = req.body;
        const { profileId: patientId, id: userId } = req.user;

        // Validate rating
        if (!rating || rating < 1 || rating > 5) {
            return sendError(res, 400, 'Rating is required and must be between 1 and 5');
        }

        // Check if appointment exists
        const appointment = await Appointment.findById(appointmentId);
        if (!appointment) {
            return sendError(res, 404, 'Appointment not found');
        }

        // Verify patient owns this appointment
        if (appointment.patientId.toString() !== patientId) {
            return sendError(res, 403, 'You can only review your own appointments');
        }

        // Check if appointment is completed
        if (appointment.status !== 'completed') {
            return sendError(res, 400, 'You can only review completed appointments');
        }

        // Check if already reviewed
        const existingReview = await Review.findOne({ appointmentId });
        if (existingReview) {
            return sendError(res, 400, 'You have already reviewed this appointment');
        }

        // Create the review
        const review = await Review.create({
            appointmentId,
            patientId,
            doctorId: appointment.doctorId,
            rating: Math.round(rating), // Ensure integer
            comment: comment?.trim() || null
        });

        // Calculate new average rating for doctor
        const { rating: avgRating, totalReviews } = await Review.calculateAverageRating(appointment.doctorId);

        // Emit Kafka event to update doctor's rating in user-service
        try {
            await kafkaProducer.send({
                topic: TOPICS.RDV.DOCTOR_RATING_UPDATED,
                messages: [
                    createEvent('doctor.rating.updated', {
                        doctorId: appointment.doctorId.toString(),
                        rating: avgRating,
                        totalReviews
                    })
                ]
            });
        } catch (kafkaError) {
            console.error('Failed to emit doctor.rating.updated event:', kafkaError);
        }

        // Emit Kafka event to notify doctor of new review
        try {
            await kafkaProducer.send({
                topic: TOPICS.RDV.REVIEW_CREATED,
                messages: [
                    createEvent('review.created', {
                        doctorId: appointment.doctorId.toString(),
                        patientId: patientId,
                        appointmentId: appointmentId,
                        rating: review.rating,
                        hasComment: !!review.comment,
                        reviewId: review._id.toString()
                    })
                ]
            });
        } catch (kafkaError) {
            console.error('Failed to emit review.created notification event:', kafkaError);
        }

        return sendSuccess(res, 201, 'Review submitted successfully', {
            review: {
                _id: review._id,
                rating: review.rating,
                comment: review.comment,
                createdAt: review.createdAt
            },
            doctorStats: {
                averageRating: avgRating,
                totalReviews
            }
        });

    } catch (error) {
        next(error);
    }
};

/**
 * Get all reviews for a doctor
 * GET /api/v1/reviews/doctors/:doctorId
 */
export const getDoctorReviews = async (req, res, next) => {
    try {
        const { doctorId } = req.params;
        const { page = 1, limit = 10 } = req.query;

        // Validate doctorId
        if (!mongoose.Types.ObjectId.isValid(doctorId)) {
            return sendError(res, 400, 'Invalid doctor ID');
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);

        // Get reviews with pagination
        const [reviews, total, stats] = await Promise.all([
            Review.find({ doctorId })
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit))
                .lean(),
            Review.countDocuments({ doctorId }),
            Review.calculateAverageRating(doctorId)
        ]);

        return sendSuccess(res, 200, 'Reviews retrieved successfully', {
            reviews,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / parseInt(limit)),
                totalReviews: total,
                hasMore: skip + reviews.length < total
            },
            stats: {
                averageRating: stats.rating,
                totalReviews: stats.totalReviews
            }
        });

    } catch (error) {
        next(error);
    }
};

/**
 * Get review for a specific appointment
 * GET /api/v1/reviews/appointments/:appointmentId
 */
export const getAppointmentReview = async (req, res, next) => {
    try {
        const { appointmentId } = req.params;
        const { profileId, role } = req.user;

        // Validate appointmentId
        if (!mongoose.Types.ObjectId.isValid(appointmentId)) {
            return sendError(res, 400, 'Invalid appointment ID');
        }

        // Check if appointment exists and user has access
        const appointment = await Appointment.findById(appointmentId);
        if (!appointment) {
            return sendError(res, 404, 'Appointment not found');
        }

        // Verify user has access (patient or doctor of this appointment)
        const isPatient = role === 'patient' && appointment.patientId.toString() === profileId;
        const isDoctor = role === 'doctor' && appointment.doctorId.toString() === profileId;
        
        if (!isPatient && !isDoctor) {
            return sendError(res, 403, 'You do not have access to this review');
        }

        const review = await Review.findOne({ appointmentId }).lean();

        if (!review) {
            return sendSuccess(res, 200, 'No review found for this appointment', {
                review: null,
                canReview: isPatient && appointment.status === 'completed'
            });
        }

        return sendSuccess(res, 200, 'Review retrieved successfully', { review });

    } catch (error) {
        next(error);
    }
};

/**
 * Patient: Update a review (only within 24 hours of creation)
 * PUT /api/v1/reviews/:reviewId
 */
export const updateReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;
        const { rating, comment } = req.body;
        const { profileId: patientId } = req.user;

        // Find the review
        const review = await Review.findById(reviewId);
        if (!review) {
            return sendError(res, 404, 'Review not found');
        }

        // Verify ownership
        if (review.patientId.toString() !== patientId) {
            return sendError(res, 403, 'You can only edit your own reviews');
        }

        // Check if within 24 hours
        const hoursSinceCreation = (Date.now() - review.createdAt.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCreation > 24) {
            return sendError(res, 400, 'Reviews can only be edited within 24 hours of submission');
        }

        // Update fields
        if (rating !== undefined) {
            if (rating < 1 || rating > 5) {
                return sendError(res, 400, 'Rating must be between 1 and 5');
            }
            review.rating = Math.round(rating);
        }
        if (comment !== undefined) {
            review.comment = comment?.trim() || null;
        }

        await review.save();

        // Recalculate average rating
        const { rating: avgRating, totalReviews } = await Review.calculateAverageRating(review.doctorId);

        // Emit event to update doctor's rating
        try {
            await kafkaProducer.send({
                topic: TOPICS.RDV.DOCTOR_RATING_UPDATED,
                messages: [
                    createEvent('doctor.rating.updated', {
                        doctorId: review.doctorId.toString(),
                        rating: avgRating,
                        totalReviews
                    })
                ]
            });
        } catch (kafkaError) {
            console.error('Failed to emit doctor.rating.updated event:', kafkaError);
        }

        return sendSuccess(res, 200, 'Review updated successfully', {
            review: {
                _id: review._id,
                rating: review.rating,
                comment: review.comment,
                updatedAt: review.updatedAt
            },
            doctorStats: {
                averageRating: avgRating,
                totalReviews
            }
        });

    } catch (error) {
        next(error);
    }
};

/**
 * Patient: Delete a review (only within 24 hours of creation)
 * DELETE /api/v1/reviews/:reviewId
 */
export const deleteReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;
        const { profileId: patientId } = req.user;

        // Find the review
        const review = await Review.findById(reviewId);
        if (!review) {
            return sendError(res, 404, 'Review not found');
        }

        // Verify ownership
        if (review.patientId.toString() !== patientId) {
            return sendError(res, 403, 'You can only delete your own reviews');
        }

        // Check if within 24 hours
        const hoursSinceCreation = (Date.now() - review.createdAt.getTime()) / (1000 * 60 * 60);
        if (hoursSinceCreation > 24) {
            return sendError(res, 400, 'Reviews can only be deleted within 24 hours of submission');
        }

        const doctorId = review.doctorId;
        await review.deleteOne();

        // Recalculate average rating
        const { rating: avgRating, totalReviews } = await Review.calculateAverageRating(doctorId);

        // Emit event to update doctor's rating
        try {
            await kafkaProducer.send({
                topic: TOPICS.RDV.DOCTOR_RATING_UPDATED,
                messages: [
                    createEvent('doctor.rating.updated', {
                        doctorId: doctorId.toString(),
                        rating: avgRating,
                        totalReviews
                    })
                ]
            });
        } catch (kafkaError) {
            console.error('Failed to emit doctor.rating.updated event:', kafkaError);
        }

        return sendSuccess(res, 200, 'Review deleted successfully', {
            doctorStats: {
                averageRating: avgRating,
                totalReviews
            }
        });

    } catch (error) {
        next(error);
    }
};
