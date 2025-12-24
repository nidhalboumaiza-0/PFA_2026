import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/domain/repositories/user_repository.dart';

class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<Either<Failure, Unit>> call(UserEntity user) async {
    if (user is PatientModel) {
      return await repository.updatePatientProfile(user);
    } else if (user is MedecinModel) {
      return await repository.updateDoctorProfile(user);
    } else {
      // Handle generic UserEntity or other types if necessary
      // For now, we assume it's either PatientModel or MedecinModel
      // Ideally, UserEntity should be abstract or we cast it
      if (user.role == 'patient') {
         // We might need to convert UserEntity to PatientModel if it's not already
         // But in our app, we usually work with the subclasses
         return await repository.updatePatientProfile(user as PatientModel);
      } else if (user.role == 'medecin') {
         return await repository.updateDoctorProfile(user as MedecinModel);
      }
      return Left(ServerFailure(message: 'Unsupported user type'));
    }
  }
}
