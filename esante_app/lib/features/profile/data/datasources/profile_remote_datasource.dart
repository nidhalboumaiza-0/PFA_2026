import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/patient_profile_model.dart';
import '../models/doctor_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<PatientProfileModel> getPatientProfile();
  Future<PatientProfileModel> updatePatientProfile(Map<String, dynamic> data);
  Future<DoctorProfileModel> getDoctorProfile();
  Future<DoctorProfileModel> updateDoctorProfile(Map<String, dynamic> data);
  Future<String> uploadProfilePhoto(String filePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;
  final Dio _dio;

  ProfileRemoteDataSourceImpl({
    required ApiClient apiClient,
    required Dio dio,
  }) : _apiClient = apiClient,
       _dio = dio;

  void _log(String method, String message) {
    print('[ProfileRemoteDataSource.$method] $message');
  }

  @override
  Future<PatientProfileModel> getPatientProfile() async {
    _log('getPatientProfile', 'Fetching patient profile...');
    try {
      final response = await _apiClient.get(ApiList.userMe);
      _log('getPatientProfile', 'Response: $response');
      
      // The response might have the profile directly or in a data wrapper
      final profileData = response['data']?['profile'] ?? response['profile'] ?? response;
      return PatientProfileModel.fromJson(profileData);
    } catch (e) {
      _log('getPatientProfile', 'Error: $e');
      rethrow;
    }
  }

  @override
  Future<PatientProfileModel> updatePatientProfile(Map<String, dynamic> data) async {
    _log('updatePatientProfile', 'Updating profile with: $data');
    try {
      final response = await _apiClient.put(
        ApiList.patientProfile,
        data: data,
      );
      _log('updatePatientProfile', 'Response: $response');
      
      final profileData = response['data']?['profile'] ?? response['profile'] ?? response;
      return PatientProfileModel.fromJson(profileData);
    } catch (e) {
      _log('updatePatientProfile', 'Error: $e');
      rethrow;
    }
  }

  @override
  Future<DoctorProfileModel> getDoctorProfile() async {
    _log('getDoctorProfile', 'Fetching doctor profile...');
    try {
      final response = await _apiClient.get(ApiList.userMe);
      _log('getDoctorProfile', 'Response: $response');
      
      final profileData = response['data']?['profile'] ?? response['profile'] ?? response;
      return DoctorProfileModel.fromJson(profileData);
    } catch (e) {
      _log('getDoctorProfile', 'Error: $e');
      rethrow;
    }
  }

  @override
  Future<DoctorProfileModel> updateDoctorProfile(Map<String, dynamic> data) async {
    _log('updateDoctorProfile', 'Updating doctor profile with: $data');
    try {
      final response = await _apiClient.put(
        ApiList.doctorProfile,
        data: data,
      );
      _log('updateDoctorProfile', 'Response: $response');
      
      final profileData = response['data']?['profile'] ?? response['profile'] ?? response;
      return DoctorProfileModel.fromJson(profileData);
    } catch (e) {
      _log('updateDoctorProfile', 'Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfilePhoto(String filePath) async {
    _log('uploadProfilePhoto', 'Uploading photo from: $filePath');
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiList.userUploadPhoto,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      _log('uploadProfilePhoto', 'Response: ${response.data}');
      
      // Return the photo URL
      final data = response.data as Map<String, dynamic>;
      return data['data']?['photoUrl'] ?? data['photoUrl'] ?? '';
    } catch (e) {
      _log('uploadProfilePhoto', 'Error: $e');
      rethrow;
    }
  }
}
