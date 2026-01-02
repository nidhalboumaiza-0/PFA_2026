import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/review_repository.dart';

/// Use case for getting all reviews for a doctor
class GetDoctorReviewsUseCase implements UseCase<DoctorReviewsResult, GetDoctorReviewsParams> {
  final ReviewRepository _repository;

  GetDoctorReviewsUseCase(this._repository);

  @override
  Future<Either<Failure, DoctorReviewsResult>> call(GetDoctorReviewsParams params) {
    return _repository.getDoctorReviews(
      doctorId: params.doctorId,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetDoctorReviewsParams extends Equatable {
  final String doctorId;
  final int page;
  final int limit;

  const GetDoctorReviewsParams({
    required this.doctorId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [doctorId, page, limit];
}
