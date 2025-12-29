import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/patient_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdatePatientProfileParams {
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final Map<String, dynamic>? address;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? insuranceInfo;

  const UpdatePatientProfileParams({
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.address,
    this.bloodType,
    this.allergies,
    this.chronicDiseases,
    this.emergencyContact,
    this.insuranceInfo,
  });
}

class UpdatePatientProfileUseCase {
  final ProfileRepository _repository;

  UpdatePatientProfileUseCase(this._repository);

  Future<Either<Failure, PatientProfileEntity>> call(UpdatePatientProfileParams params) {
    return _repository.updatePatientProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      dateOfBirth: params.dateOfBirth,
      gender: params.gender,
      phone: params.phone,
      address: params.address,
      bloodType: params.bloodType,
      allergies: params.allergies,
      chronicDiseases: params.chronicDiseases,
      emergencyContact: params.emergencyContact,
      insuranceInfo: params.insuranceInfo,
    );
  }
}
