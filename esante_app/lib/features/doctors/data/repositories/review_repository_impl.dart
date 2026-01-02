import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/doctor_review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;

  ReviewRepositoryImpl({required ReviewRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, DoctorReviewEntity>> submitReview({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final review = await _remoteDataSource.submitReview(
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
      );
      return Right(review);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, DoctorReviewsResult>> getDoctorReviews({
    required String doctorId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _remoteDataSource.getDoctorReviews(
        doctorId: doctorId,
        page: page,
        limit: limit,
      );
      
      return Right(DoctorReviewsResult(
        reviews: response.reviews,
        stats: response.stats,
        total: response.total,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
      ));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, DoctorReviewEntity?>> getAppointmentReview({
    required String appointmentId,
  }) async {
    try {
      final review = await _remoteDataSource.getAppointmentReview(
        appointmentId: appointmentId,
      );
      return Right(review);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, DoctorReviewEntity>> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final review = await _remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      return Right(review);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview({
    required String reviewId,
  }) async {
    try {
      await _remoteDataSource.deleteReview(reviewId: reviewId);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Failure _handleError(Object e) {
    if (e is Failure) {
      return e;
    }
    final message = e.toString();
    if (message.contains('400')) {
      if (message.contains('already reviewed')) {
        return const ServerFailure(
          code: 'ALREADY_REVIEWED',
          message: 'You have already reviewed this appointment',
        );
      }
      return const ServerFailure(
        code: 'INVALID_DATA',
        message: 'Invalid review data',
      );
    }
    if (message.contains('403')) {
      return const ServerFailure(
        code: 'FORBIDDEN',
        message: 'You can only review your own appointments',
      );
    }
    if (message.contains('404')) {
      return const ServerFailure(
        code: 'NOT_FOUND',
        message: 'Appointment not found',
      );
    }
    return ServerFailure(code: 'UNKNOWN', message: message);
  }
}
