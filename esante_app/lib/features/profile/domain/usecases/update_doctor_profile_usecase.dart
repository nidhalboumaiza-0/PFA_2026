import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateDoctorProfileParams {
  final String? firstName;
  final String? lastName;
  final String? specialty;
  final String? subSpecialty;
  final String? phone;
  final String? licenseNumber;
  final int? yearsOfExperience;
  final List<Map<String, dynamic>>? education;
  final List<String>? languages;
  final String? clinicName;
  final Map<String, dynamic>? clinicAddress;
  final String? about;
  final double? consultationFee;
  final bool? acceptsInsurance;
  final List<Map<String, dynamic>>? workingHours;

  const UpdateDoctorProfileParams({
    this.firstName,
    this.lastName,
    this.specialty,
    this.subSpecialty,
    this.phone,
    this.licenseNumber,
    this.yearsOfExperience,
    this.education,
    this.languages,
    this.clinicName,
    this.clinicAddress,
    this.about,
    this.consultationFee,
    this.acceptsInsurance,
    this.workingHours,
  });
}

class UpdateDoctorProfileUseCase {
  final ProfileRepository _repository;

  UpdateDoctorProfileUseCase(this._repository);

  Future<Either<Failure, DoctorProfileEntity>> call(UpdateDoctorProfileParams params) {
    return _repository.updateDoctorProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      specialty: params.specialty,
      subSpecialty: params.subSpecialty,
      phone: params.phone,
      licenseNumber: params.licenseNumber,
      yearsOfExperience: params.yearsOfExperience,
      education: params.education,
      languages: params.languages,
      clinicName: params.clinicName,
      clinicAddress: params.clinicAddress,
      about: params.about,
      consultationFee: params.consultationFee,
      acceptsInsurance: params.acceptsInsurance,
      workingHours: params.workingHours,
    );
  }
}
