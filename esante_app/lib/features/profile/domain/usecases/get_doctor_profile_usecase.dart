import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetDoctorProfileUseCase {
  final ProfileRepository _repository;

  GetDoctorProfileUseCase(this._repository);

  Future<Either<Failure, DoctorProfileEntity>> call() {
    return _repository.getDoctorProfile();
  }
}
