import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/patient_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetPatientProfileUseCase {
  final ProfileRepository _repository;

  GetPatientProfileUseCase(this._repository);

  Future<Either<Failure, PatientProfileEntity>> call() {
    return _repository.getPatientProfile();
  }
}
