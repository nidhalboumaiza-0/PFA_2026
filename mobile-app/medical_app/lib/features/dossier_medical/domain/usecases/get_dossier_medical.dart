import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import '../entities/dossier_medical_entity.dart';
import '../repositories/dossier_medical_repository.dart';

class GetDossierMedical implements UseCase<DossierMedicalEntity, Params> {
  final DossierMedicalRepository repository;

  GetDossierMedical(this.repository);

  @override
  Future<Either<Failure, DossierMedicalEntity>> call(Params params) async {
    return await repository.getDossierMedical(params.patientId);
  }
}

class Params extends Equatable {
  final String patientId;

  const Params({required this.patientId});

  @override
  List<Object> get props => [patientId];
}
