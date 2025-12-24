import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import '../repositories/dossier_medical_repository.dart';

class HasDossierMedical implements UseCase<bool, Params> {
  final DossierMedicalRepository repository;

  HasDossierMedical(this.repository);

  @override
  Future<Either<Failure, bool>> call(Params params) async {
    return await repository.hasDossierMedical(params.patientId);
  }
}

class Params extends Equatable {
  final String patientId;

  const Params({required this.patientId});

  @override
  List<Object> get props => [patientId];
}
