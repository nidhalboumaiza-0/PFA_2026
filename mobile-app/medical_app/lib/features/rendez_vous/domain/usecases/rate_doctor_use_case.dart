import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class RateDoctorUseCase {
  final RendezVousRepository repository;

  RateDoctorUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String appointmentId,
    required double rating,
  }) async {
    return await repository.rateDoctor(appointmentId, rating);
  }
}
