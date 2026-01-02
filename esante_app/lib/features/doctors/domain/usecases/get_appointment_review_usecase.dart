import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/doctor_review_entity.dart';
import '../repositories/review_repository.dart';

/// Use case for getting review for a specific appointment
class GetAppointmentReviewUseCase implements UseCase<DoctorReviewEntity?, GetAppointmentReviewParams> {
  final ReviewRepository _repository;

  GetAppointmentReviewUseCase(this._repository);

  @override
  Future<Either<Failure, DoctorReviewEntity?>> call(GetAppointmentReviewParams params) {
    return _repository.getAppointmentReview(appointmentId: params.appointmentId);
  }
}

class GetAppointmentReviewParams extends Equatable {
  final String appointmentId;

  const GetAppointmentReviewParams({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}
