import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for the API
  static const String baseUrl = 'http://192.168.1.204:3000/api/v1';

  // Constructor to allow dependency injection
  ApiService();

  // Headers for API requests
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'An error occurred');
    }
  }

  // Generic request methods
  static Future<dynamic> getRequest(String url) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  static Future<dynamic> postRequest(
    String url,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> putRequest(
    String url,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patchRequest(
    String url,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> deleteRequest(String url) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  // Authentication methods
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    final data = _handleResponse(response);

    // Save token to shared preferences
    if (data != null && data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('user_id', data['user']['_id']);
      await prefs.setString('user_role', data['user']['role']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    return _handleResponse(response);
  }

  static Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    return true;
  }

  static Future<Map<String, dynamic>> verifyAccount(
    String email,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'verificationCode': code}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'passwordResetCode': code,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // ==================== User Service Methods ====================

  /// Get current user profile
  /// GET /api/v1/users/me
  static Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  /// Update patient profile
  /// PUT /api/v1/users/patient/profile
  static Future<Map<String, dynamic>> updatePatientProfile(
    Map<String, dynamic> profileData,
  ) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/users/patient/profile'),
      headers: headers,
      body: json.encode(profileData),
    );

    return _handleResponse(response);
  }

  /// Update doctor profile
  /// PUT /api/v1/users/doctor/profile
  static Future<Map<String, dynamic>> updateDoctorProfile(
    Map<String, dynamic> profileData,
  ) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/users/doctor/profile'),
      headers: headers,
      body: json.encode(profileData),
    );

    return _handleResponse(response);
  }

  /// Upload profile photo
  /// POST /api/v1/users/upload-photo
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    String filePath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/upload-photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  /// Update OneSignal Player ID for push notifications
  /// PATCH /api/v1/users/updateOneSignalPlayerId
  static Future<Map<String, dynamic>> updateOneSignalPlayerId(
    String playerId,
  ) async {
    final headers = await _getHeaders();

    final response = await http.patch(
      Uri.parse('$baseUrl/users/updateOneSignalPlayerId'),
      headers: headers,
      body: json.encode({'oneSignalPlayerId': playerId}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final headers = await _getHeaders();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: headers,
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  // ==================== Doctor Search Methods ====================

  /// Search doctors with filters
  /// GET /api/v1/users/doctors/search
  static Future<Map<String, dynamic>> searchDoctors({
    String? name,
    String? specialty,
    String? city,
    double? latitude,
    double? longitude,
    int? radius,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _getHeaders();

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (name != null) queryParams['name'] = name;
    if (specialty != null) queryParams['specialty'] = specialty;
    if (city != null) queryParams['city'] = city;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (radius != null) queryParams['radius'] = radius.toString();

    final uri = Uri.parse('$baseUrl/users/doctors/search').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: headers);

    return _handleResponse(response);
  }

  /// Get doctors by specialty (convenience method)
  static Future<List<dynamic>> getDoctorsBySpecialty(String specialty) async {
    final data = await searchDoctors(specialty: specialty);
    return data['doctors'] ?? [];
  }

  /// Get nearby doctors for map view
  /// GET /api/v1/users/doctors/nearby
  static Future<List<dynamic>> getNearbyDoctors({
    required double latitude,
    required double longitude,
    int radius = 5,
    String? specialty,
  }) async {
    final headers = await _getHeaders();

    final queryParams = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    };

    if (specialty != null) queryParams['specialty'] = specialty;

    final uri = Uri.parse('$baseUrl/users/doctors/nearby').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: headers);

    final data = _handleResponse(response);
    return data['doctors'] ?? [];
  }

  /// Get doctor by ID (public profile)
  /// GET /api/v1/users/doctors/:doctorId
  static Future<Map<String, dynamic>> getDoctorById(String doctorId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/users/doctors/$doctorId'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  /// Alias for getDoctorById for backward compatibility
  static Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    return getDoctorById(doctorId);
  }

  // Appointment methods
  static Future<List<dynamic>> getAppointments({
    String? patientId,
    String? doctorId,
  }) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/appointments?';

    if (patientId != null) url += 'patientId=$patientId&';
    if (doctorId != null) url += 'doctorId=$doctorId&';

    final response = await http.get(Uri.parse(url), headers: headers);

    final data = _handleResponse(response);
    return data['appointments'] ?? [];
  }

  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: headers,
      body: json.encode(appointmentData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final headers = await _getHeaders();

    final response = await http.patch(
      Uri.parse('$baseUrl/appointments/$appointmentId/status'),
      headers: headers,
      body: json.encode({'status': status}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAppointmentDetails(
    String appointmentId,
  ) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: headers,
    );

    return _handleResponse(response);
  }
}
