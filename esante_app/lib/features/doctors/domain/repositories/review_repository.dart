import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_review_entity.dart';

/// Repository interface for doctor reviews
abstract class ReviewRepository {
  /// Submit a review for a completed appointment
  Future<Either<Failure, DoctorReviewEntity>> submitReview({
    required String appointmentId,
    required int rating,
    String? comment,
  });

  /// Get all reviews for a doctor with stats
  Future<Either<Failure, DoctorReviewsResult>> getDoctorReviews({
    required String doctorId,
    int page = 1,
    int limit = 10,
  });

  /// Get review for a specific appointment (if exists)
  Future<Either<Failure, DoctorReviewEntity?>> getAppointmentReview({
    required String appointmentId,
  });

  /// Update a review (within 24 hours of creation)
  Future<Either<Failure, DoctorReviewEntity>> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  });

  /// Delete a review (within 24 hours of creation)
  Future<Either<Failure, void>> deleteReview({
    required String reviewId,
  });
}

/// Result class for doctor reviews including stats
class DoctorReviewsResult {
  final List<DoctorReviewEntity> reviews;
  final DoctorRatingStats stats;
  final int total;
  final int currentPage;
  final int totalPages;

  DoctorReviewsResult({
    required this.reviews,
    required this.stats,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });
}
