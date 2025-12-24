import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUserProfile();
  Future<Unit> updatePatientProfile(PatientModel patient);
  Future<Unit> updateDoctorProfile(MedecinModel doctor);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  UserRemoteDataSourceImpl({
    required this.client,
    required this.localDataSource,
  });

  // Helper: Map gender from backend (male/female/other) to app (Homme/Femme/Autre)
  String _mapGenderFromBackend(String? backendGender) {
    if (backendGender == null) return 'Homme';
    switch (backendGender.toLowerCase()) {
      case 'male':
        return 'Homme';
      case 'female':
        return 'Femme';
      case 'other':
        return 'Autre';
      default:
        return 'Homme';
    }
  }

  // Helper: Map gender from app (Homme/Femme/Autre) to backend (male/female/other)
  String _mapGenderToBackend(String appGender) {
    switch (appGender) {
      case 'Homme':
        return 'male';
      case 'Femme':
        return 'female';
      case 'Autre':
        return 'other';
      default:
        return 'male';
    }
  }

  void _handleHttpError(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'Unknown error';
      
      if (response.statusCode == 401) {
        throw UnauthorizedException(message);
      } else if (response.statusCode == 403) {
        throw AuthException(message: message);
      } else if (response.statusCode == 404) {
        throw AuthException(message: message);
      } else if (response.statusCode == 400) {
        throw AuthException(message: message);
      } else {
        throw ServerException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is AuthException || e is UnauthorizedException) rethrow;
      throw ServerException(message: 'Server error: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) throw AuthException(message: 'Not authenticated');

      final response = await client.get(
        Uri.parse(AppConstants.getUserProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        final userObj = profileData['user'];
        final profileObj = profileData['profile'];

        final Map<String, dynamic> mergedData = {
          'id': userObj['id'],
          'email': userObj['email'],
          'role': userObj['role'] == 'doctor' ? 'medecin' : userObj['role'],
          'name': profileObj['firstName'] ?? '',
          'lastName': profileObj['lastName'] ?? '',
          'gender': _mapGenderFromBackend(profileObj['gender']),
          'phoneNumber': profileObj['phone'] ?? '',
          'dateOfBirth': profileObj['dateOfBirth'],
          'profilePicture': profileObj['profilePhoto'],
          'accountStatus': userObj['isActive'] ?? true,
        };

        if (userObj['role'] == 'doctor') {
          mergedData['speciality'] = profileObj['specialty'] ?? '';
          mergedData['numLicence'] = profileObj['licenseNumber'] ?? '';
          mergedData['appointmentDuration'] = profileObj['appointmentDuration'] ?? 30;
          mergedData['averageRating'] = (profileObj['rating'] ?? 0.0).toDouble();
          mergedData['totalRatings'] = profileObj['totalReviews'] ?? 0;
          mergedData['consultationFee'] = (profileObj['consultationFee'] ?? 0.0).toDouble();
          
          if (profileObj['clinicAddress']?['coordinates']?['coordinates'] != null) {
            final coords = profileObj['clinicAddress']['coordinates']['coordinates'];
            if (coords is List && coords.length >= 2) {
              mergedData['lng'] = coords[0].toDouble();
              mergedData['lat'] = coords[1].toDouble();
            }
          }
        } else {
          mergedData['antecedent'] = (profileObj['chronicDiseases'] as List?)?.join(', ') ?? '';
          mergedData['bloodType'] = profileObj['bloodType'];
          mergedData['allergies'] = profileObj['allergies'] ?? [];
          mergedData['chronicDiseases'] = profileObj['chronicDiseases'] ?? [];
        }

        final UserModel user = mergedData['role'] == 'patient'
            ? PatientModel.fromJson(mergedData)
            : MedecinModel.fromJson(mergedData);

        await localDataSource.cacheUser(user);
        return user;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to fetch profile');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is AuthException) rethrow;
      throw ServerException(message: 'Fetch profile error: $e');
    }
  }

  @override
  Future<Unit> updatePatientProfile(PatientModel patient) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) throw AuthException(message: 'Not authenticated');

      Map<String, dynamic> updateData = {
        'firstName': patient.name,
        'lastName': patient.lastName,
        'gender': _mapGenderToBackend(patient.gender),
        'phone': patient.phoneNumber,
      };

      if (patient.dateOfBirth != null) {
        updateData['dateOfBirth'] = patient.dateOfBirth!.toIso8601String();
      }
      
      // Blood type
      if (patient.bloodType?.isNotEmpty == true) {
        updateData['bloodType'] = patient.bloodType;
      }
      
      // Allergies - send as array
      if (patient.allergies != null && patient.allergies!.isNotEmpty) {
        updateData['allergies'] = patient.allergies;
      }
      
      // Chronic diseases - merge antecedent with chronicDiseases list
      List<String> chronicDiseases = [];
      if (patient.chronicDiseases != null && patient.chronicDiseases!.isNotEmpty) {
        chronicDiseases.addAll(patient.chronicDiseases!);
      }
      if (patient.antecedent != null && patient.antecedent!.isNotEmpty) {
        // Add antecedent if not already in list
        if (!chronicDiseases.contains(patient.antecedent)) {
          chronicDiseases.add(patient.antecedent!);
        }
      }
      if (chronicDiseases.isNotEmpty) {
        updateData['chronicDiseases'] = chronicDiseases;
      }
      
      // Emergency contact
      if (patient.emergencyContact != null && patient.emergencyContact!.isNotEmpty) {
        Map<String, dynamic> emergencyData = {};
        if (patient.emergencyContact!['name'] != null) {
          emergencyData['name'] = patient.emergencyContact!['name'];
        }
        if (patient.emergencyContact!['relationship'] != null) {
          emergencyData['relationship'] = patient.emergencyContact!['relationship'];
        }
        // Map 'phoneNumber' to 'phone' for backend
        if (patient.emergencyContact!['phoneNumber'] != null) {
          emergencyData['phone'] = patient.emergencyContact!['phoneNumber'];
        } else if (patient.emergencyContact!['phone'] != null) {
          emergencyData['phone'] = patient.emergencyContact!['phone'];
        }
        if (emergencyData.isNotEmpty) {
          updateData['emergencyContact'] = emergencyData;
        }
      }
      
      // Insurance info (if available)
      if (patient.insuranceInfo != null && patient.insuranceInfo!.isNotEmpty) {
        updateData['insuranceInfo'] = patient.insuranceInfo;
      }

      final response = await client.put(
        Uri.parse(AppConstants.updatePatientProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await localDataSource.cacheUser(patient);
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to update patient profile');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is AuthException) rethrow;
      throw ServerException(message: 'Update error: $e');
    }
  }

  @override
  Future<Unit> updateDoctorProfile(MedecinModel doctor) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) throw AuthException(message: 'Not authenticated');

      Map<String, dynamic> updateData = {
        'firstName': doctor.name,
        'lastName': doctor.lastName,
        'phone': doctor.phoneNumber,
        'specialty': doctor.speciality,
        'licenseNumber': doctor.numLicence,
      };

      if (doctor.dateOfBirth != null) {
        updateData['dateOfBirth'] = doctor.dateOfBirth!.toIso8601String();
      }
      if (doctor.consultationFee != null && doctor.consultationFee! > 0) {
        updateData['consultationFee'] = doctor.consultationFee;
      }
      if (doctor.yearsOfExperience != null && doctor.yearsOfExperience! > 0) {
        updateData['yearsOfExperience'] = doctor.yearsOfExperience;
      }
      if (doctor.subSpecialty?.isNotEmpty == true) {
        updateData['subSpecialty'] = doctor.subSpecialty;
      }
      if (doctor.clinicName?.isNotEmpty == true) {
        updateData['clinicName'] = doctor.clinicName;
      }
      if (doctor.about?.isNotEmpty == true) {
        updateData['about'] = doctor.about;
      }
      if (doctor.languages != null && doctor.languages!.isNotEmpty) {
        updateData['languages'] = doctor.languages;
      }
      if (doctor.acceptsInsurance != null) {
        updateData['acceptsInsurance'] = doctor.acceptsInsurance;
      }
      if (doctor.education != null && doctor.education!.isNotEmpty) {
        updateData['education'] = doctor.education;
      }
      if (doctor.workingHours != null && doctor.workingHours!.isNotEmpty) {
        updateData['workingHours'] = doctor.workingHours;
      }
      // Clinic address - send as-is, backend handles coordinate conversion
      if (doctor.clinicAddress != null && doctor.clinicAddress!.isNotEmpty) {
        updateData['clinicAddress'] = doctor.clinicAddress;
      }

      final response = await client.put(
        Uri.parse(AppConstants.updateDoctorProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await localDataSource.cacheUser(doctor);
        return unit;
      } else {
        _handleHttpError(response);
        throw ServerException(message: 'Failed to update doctor profile');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is AuthException) rethrow;
      throw ServerException(message: 'Update error: $e');
    }
  }
}
