import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/patient_profile_entity.dart';
import '../entities/doctor_profile_entity.dart';

abstract class ProfileRepository {
  /// Get current user's profile (patient or doctor based on role)
  Future<Either<Failure, PatientProfileEntity>> getPatientProfile();

  /// Update patient profile
  Future<Either<Failure, PatientProfileEntity>> updatePatientProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    Map<String, dynamic>? address,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicDiseases,
    Map<String, dynamic>? emergencyContact,
    Map<String, dynamic>? insuranceInfo,
  });

  /// Get doctor profile
  Future<Either<Failure, DoctorProfileEntity>> getDoctorProfile();

  /// Update doctor profile
  Future<Either<Failure, DoctorProfileEntity>> updateDoctorProfile({
    String? firstName,
    String? lastName,
    String? specialty,
    String? subSpecialty,
    String? phone,
    String? licenseNumber,
    int? yearsOfExperience,
    List<Map<String, dynamic>>? education,
    List<String>? languages,
    String? clinicName,
    Map<String, dynamic>? clinicAddress,
    String? about,
    double? consultationFee,
    bool? acceptsInsurance,
    List<Map<String, dynamic>>? workingHours,
  });

  /// Upload profile photo
  Future<Either<Failure, String>> uploadProfilePhoto(String filePath);

  /// Get cached profile
  Future<PatientProfileEntity?> getCachedProfile();

  /// Check if profile needs completion
  Future<bool> needsProfileCompletion();

  /// Mark that profile completion dialog has been shown
  Future<void> markProfileCompletionShown();
}
