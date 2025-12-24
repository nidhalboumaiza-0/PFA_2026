import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class FetchDoctorsBySpecialtyUseCase {
  final RendezVousRepository rendezVousRepository;

  FetchDoctorsBySpecialtyUseCase(this.rendezVousRepository);

  Future<Either<Failure, List<MedecinEntity>>> call(
    String specialty, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await rendezVousRepository.getDoctorsBySpecialty(
      specialty,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
