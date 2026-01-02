import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/doctor_review_entity.dart';
import '../repositories/review_repository.dart';

/// Use case for submitting a review for a completed appointment
class SubmitReviewUseCase implements UseCase<DoctorReviewEntity, SubmitReviewParams> {
  final ReviewRepository _repository;

  SubmitReviewUseCase(this._repository);

  @override
  Future<Either<Failure, DoctorReviewEntity>> call(SubmitReviewParams params) {
    return _repository.submitReview(
      appointmentId: params.appointmentId,
      rating: params.rating,
      comment: params.comment,
    );
  }
}

class SubmitReviewParams extends Equatable {
  final String appointmentId;
  final int rating;
  final String? comment;

  const SubmitReviewParams({
    required this.appointmentId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [appointmentId, rating, comment];
}
