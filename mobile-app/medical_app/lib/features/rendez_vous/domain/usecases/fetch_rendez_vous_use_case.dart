import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class FetchRendezVousUseCase {
  final RendezVousRepository rendezVousRepository;

  FetchRendezVousUseCase(this.rendezVousRepository);

  Future<Either<Failure, List<RendezVousEntity>>> call({
    String? patientId,
    String? doctorId,
  }) async {
    return await rendezVousRepository.getRendezVous(
      patientId: patientId,
      doctorId: doctorId,
    );
  }
}