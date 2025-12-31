import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../../domain/entities/doctor_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/patient_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  void _log(String method, String message) {
    print('[ProfileRepository.$method] $message');
  }

  @override
  Future<Either<Failure, PatientProfileEntity>> getPatientProfile() async {
    _log('getPatientProfile', 'Fetching profile...');
    try {
      final profile = await _remoteDataSource.getPatientProfile();
      _log('getPatientProfile', 'Profile fetched: ${profile.fullName}');
      
      // Cache the profile locally
      await _localDataSource.cacheProfile(profile);
      
      return Right(profile);
    } on ServerException catch (e) {
      _log('getPatientProfile', 'ServerException: ${e.code} - ${e.message}');
      
      // Handle "Profile not found" - return an empty profile for new users
      if (e.code == 'NOT_FOUND' || e.message.toLowerCase().contains('not found')) {
        _log('getPatientProfile', 'Profile not found, returning empty profile');
        return Right(_createEmptyProfile());
      }
      
      return Left(ServerFailure(code: e.code, message: e.message, details: e.details));
    } catch (e) {
      _log('getPatientProfile', 'Error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Failed to fetch profile',
      ));
    }
  }
  
  /// Creates an empty profile for new users who don't have a profile yet
  PatientProfileEntity _createEmptyProfile() {
    return PatientProfileEntity(
      id: '',
      userId: '',
      firstName: '',
      lastName: '',
      email: null,
      dateOfBirth: DateTime(2000, 1, 1),
      gender: '',
      phone: '',
      address: null,
      profilePhoto: null,
      bloodType: null,
      allergies: const [],
      chronicDiseases: const [],
      emergencyContact: null,
      insuranceInfo: null,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
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
  }) async {
    _log('updatePatientProfile', 'Updating profile...');
    try {
      final data = <String, dynamic>{};
      
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (gender != null) data['gender'] = gender;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (bloodType != null) data['bloodType'] = bloodType;
      if (allergies != null) data['allergies'] = allergies;
      if (chronicDiseases != null) data['chronicDiseases'] = chronicDiseases;
      if (emergencyContact != null) data['emergencyContact'] = emergencyContact;
      if (insuranceInfo != null) data['insuranceInfo'] = insuranceInfo;

      final profile = await _remoteDataSource.updatePatientProfile(data);
      _log('updatePatientProfile', 'Profile updated: ${profile.fullName}');
      
      // Update cached profile
      await _localDataSource.cacheProfile(profile);
      
      return Right(profile);
    } on ServerException catch (e) {
      _log('updatePatientProfile', 'ServerException: ${e.message}');
      return Left(ServerFailure(code: e.code, message: e.message, details: e.details));
    } catch (e) {
      _log('updatePatientProfile', 'Error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Failed to update profile',
      ));
    }
  }

  @override
  Future<Either<Failure, DoctorProfileEntity>> getDoctorProfile() async {
    _log('getDoctorProfile', 'Fetching doctor profile...');
    try {
      final profile = await _remoteDataSource.getDoctorProfile();
      _log('getDoctorProfile', 'Profile fetched: ${profile.fullName}');
      return Right(profile);
    } on ServerException catch (e) {
      _log('getDoctorProfile', 'ServerException: ${e.code} - ${e.message}');
      
      if (e.code == 'NOT_FOUND' || e.message.toLowerCase().contains('not found')) {
        _log('getDoctorProfile', 'Profile not found, returning empty profile');
        return Right(_createEmptyDoctorProfile());
      }
      
      return Left(ServerFailure(code: e.code, message: e.message, details: e.details));
    } catch (e) {
      _log('getDoctorProfile', 'Error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Failed to fetch doctor profile',
      ));
    }
  }

  DoctorProfileEntity _createEmptyDoctorProfile() {
    return DoctorProfileEntity(
      id: '',
      odoctorId: '',
      firstName: '',
      lastName: '',
      specialty: '',
      phone: '',
      licenseNumber: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
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
  }) async {
    _log('updateDoctorProfile', 'Updating doctor profile...');
    try {
      final data = <String, dynamic>{};
      
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (specialty != null) data['specialty'] = specialty;
      if (subSpecialty != null) data['subSpecialty'] = subSpecialty;
      if (phone != null) data['phone'] = phone;
      if (licenseNumber != null) data['licenseNumber'] = licenseNumber;
      if (yearsOfExperience != null) data['yearsOfExperience'] = yearsOfExperience;
      if (education != null) data['education'] = education;
      if (languages != null) data['languages'] = languages;
      if (clinicName != null) data['clinicName'] = clinicName;
      if (clinicAddress != null) data['clinicAddress'] = clinicAddress;
      if (about != null) data['about'] = about;
      if (consultationFee != null) data['consultationFee'] = consultationFee;
      if (acceptsInsurance != null) data['acceptsInsurance'] = acceptsInsurance;
      if (workingHours != null) data['workingHours'] = workingHours;

      final profile = await _remoteDataSource.updateDoctorProfile(data);
      _log('updateDoctorProfile', 'Profile updated: ${profile.fullName}');
      
      return Right(profile);
    } on ServerException catch (e) {
      _log('updateDoctorProfile', 'ServerException: ${e.message}');
      return Left(ServerFailure(code: e.code, message: e.message, details: e.details));
    } catch (e) {
      _log('updateDoctorProfile', 'Error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Failed to update doctor profile',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(String filePath) async {
    _log('uploadProfilePhoto', 'Uploading photo...');
    try {
      final photoUrl = await _remoteDataSource.uploadProfilePhoto(filePath);
      _log('uploadProfilePhoto', 'Photo uploaded: $photoUrl');
      
      // Update cached profile with new photo URL
      final cachedProfile = await _localDataSource.getCachedProfile();
      if (cachedProfile != null) {
        final updatedProfile = PatientProfileModel(
          id: cachedProfile.id,
          userId: cachedProfile.userId,
          firstName: cachedProfile.firstName,
          lastName: cachedProfile.lastName,
          dateOfBirth: cachedProfile.dateOfBirth,
          gender: cachedProfile.gender,
          phone: cachedProfile.phone,
          address: cachedProfile.address != null 
              ? AddressModel.fromEntity(cachedProfile.address!) 
              : null,
          profilePhoto: photoUrl,
          bloodType: cachedProfile.bloodType,
          allergies: cachedProfile.allergies,
          chronicDiseases: cachedProfile.chronicDiseases,
          emergencyContact: cachedProfile.emergencyContact != null 
              ? EmergencyContactModel.fromEntity(cachedProfile.emergencyContact!) 
              : null,
          insuranceInfo: cachedProfile.insuranceInfo != null 
              ? InsuranceInfoModel.fromEntity(cachedProfile.insuranceInfo!) 
              : null,
          isActive: cachedProfile.isActive,
          createdAt: cachedProfile.createdAt,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.cacheProfile(updatedProfile);
      }
      
      return Right(photoUrl);
    } on ServerException catch (e) {
      _log('uploadProfilePhoto', 'ServerException: ${e.message}');
      return Left(ServerFailure(code: e.code, message: e.message, details: e.details));
    } catch (e) {
      _log('uploadProfilePhoto', 'Error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'Failed to upload photo',
      ));
    }
  }

  @override
  Future<PatientProfileEntity?> getCachedProfile() async {
    return _localDataSource.getCachedProfile();
  }

  @override
  Future<bool> needsProfileCompletion() async {
    return _localDataSource.needsProfileCompletion();
  }

  @override
  Future<void> markProfileCompletionShown() async {
    await _localDataSource.setProfileCompletionShown();
  }
}
