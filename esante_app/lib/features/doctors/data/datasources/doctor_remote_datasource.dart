import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/doctor_model.dart';

abstract class DoctorRemoteDataSource {
  /// Search doctors with filters
  Future<DoctorSearchResponse> searchDoctors({
    String? specialty,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    double radius = 10,
    int page = 1,
    int limit = 20,
  });

  /// Get nearby doctors
  Future<DoctorSearchResponse> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radius = 5,
    String? specialty,
    int page = 1,
    int limit = 20,
  });

  /// Get doctor by ID
  Future<DoctorModel> getDoctorById(String doctorId);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final ApiClient _apiClient;

  DoctorRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[DoctorRemoteDataSource.$method] $message');
  }

  @override
  Future<DoctorSearchResponse> searchDoctors({
    String? specialty,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    double radius = 10,
    int page = 1,
    int limit = 20,
  }) async {
    _log('searchDoctors', 'Searching: specialty=$specialty, lat=$latitude, lng=$longitude');
    
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'radius': radius,
    };
    
    if (specialty != null && specialty.isNotEmpty) {
      queryParams['specialty'] = specialty;
    }
    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (latitude != null) {
      queryParams['latitude'] = latitude;
    }
    if (longitude != null) {
      queryParams['longitude'] = longitude;
    }

    final response = await _apiClient.get(
      ApiList.doctorsSearch,
      queryParameters: queryParams,
    );

    _log('searchDoctors', 'Found ${(response['doctors'] as List?)?.length ?? 0} doctors');

    return DoctorSearchResponse.fromJson(response);
  }

  @override
  Future<DoctorSearchResponse> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radius = 5,
    String? specialty,
    int page = 1,
    int limit = 20,
  }) async {
    _log('getNearbyDoctors', 'Getting nearby doctors: lat=$latitude, lng=$longitude');
    
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'page': page,
      'limit': limit,
    };
    
    if (specialty != null && specialty.isNotEmpty) {
      queryParams['specialty'] = specialty;
    }

    final response = await _apiClient.get(
      ApiList.doctorsNearby,
      queryParameters: queryParams,
    );

    return DoctorSearchResponse.fromJson(response);
  }

  @override
  Future<DoctorModel> getDoctorById(String doctorId) async {
    _log('getDoctorById', 'Getting doctor: $doctorId');
    
    final response = await _apiClient.get(ApiList.doctorById(doctorId));
    
    final doctorData = response['doctor'] as Map<String, dynamic>;
    return DoctorModel.fromJson(doctorData);
  }
}

/// Response wrapper for doctor search
class DoctorSearchResponse {
  final List<DoctorModel> doctors;
  final int currentPage;
  final int totalPages;
  final int totalDoctors;

  DoctorSearchResponse({
    required this.doctors,
    required this.currentPage,
    required this.totalPages,
    required this.totalDoctors,
  });

  factory DoctorSearchResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>?;
    
    return DoctorSearchResponse(
      doctors: (json['doctors'] as List<dynamic>?)
              ?.map((d) => DoctorModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: pagination?['currentPage'] ?? 1,
      totalPages: pagination?['totalPages'] ?? 1,
      totalDoctors: pagination?['totalDoctors'] ?? 0,
    );
  }
}
