import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class CreateRendezVousUseCase {
  final RendezVousRepository rendezVousRepository;

  CreateRendezVousUseCase(this.rendezVousRepository);

  Future<Either<Failure, Unit>> call(RendezVousEntity rendezVous) async {
    return await rendezVousRepository.createRendezVous(rendezVous);
  }
}