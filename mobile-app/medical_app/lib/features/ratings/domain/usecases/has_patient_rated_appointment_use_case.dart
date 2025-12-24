import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';

class HasPatientRatedAppointmentUseCase {
  final RatingRepository repository;

  HasPatientRatedAppointmentUseCase(this.repository);

  Future<Either<Failure, bool>> call(
    String patientId,
    String rendezVousId,
  ) async {
    return await repository.hasPatientRatedAppointment(patientId, rendezVousId);
  }
}
