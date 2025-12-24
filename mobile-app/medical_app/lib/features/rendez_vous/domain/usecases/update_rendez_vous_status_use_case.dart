import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class UpdateRendezVousStatusUseCase {
  final RendezVousRepository rendezVousRepository;

  UpdateRendezVousStatusUseCase(this.rendezVousRepository);

  Future<Either<Failure, Unit>> call({
    required String rendezVousId,
    required String status,
  }) async {
    return await rendezVousRepository.updateRendezVousStatus(
      rendezVousId,
      status,
    );
  }
}
