import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, UserEntity>> getUserProfile();
  Future<Either<Failure, Unit>> updatePatientProfile(PatientModel patient);
  Future<Either<Failure, Unit>> updateDoctorProfile(MedecinModel doctor);
}
