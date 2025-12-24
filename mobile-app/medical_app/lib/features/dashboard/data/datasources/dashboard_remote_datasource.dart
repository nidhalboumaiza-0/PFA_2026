import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../rendez_vous/data/models/RendezVous.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  /// Fetch upcoming appointments for a doctor
  /// Throws [ServerException] if something goes wrong
  Future<List<RendezVousModel>> getUpcomingAppointments(
    String doctorId, {
    int limit = 5,
  });

  /// Count appointments by status for a doctor
  /// Throws [ServerException] if something goes wrong
  Future<Map<String, int>> getAppointmentsCountByStatus(String doctorId);

  /// Count total patients for a doctor
  /// Throws [ServerException] if something goes wrong
  Future<int> getTotalPatientsCount(String doctorId);

  /// Fetch complete dashboard statistics for a doctor
  /// Throws [ServerException] if something goes wrong
  Future<DashboardStatsModel> getDoctorDashboardStats(String doctorId);

  /// Method to fetch doctor's patients with pagination
  Future<Map<String, dynamic>> getDoctorPatients(
    String doctorId, {
    int limit = 10,
    String? lastPatientId,
  });
}

class MongoDBDashboardRemoteDataSourceImpl
    implements DashboardRemoteDataSource {
  final http.Client client;

  MongoDBDashboardRemoteDataSourceImpl({required this.client});

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('TOKEN');
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        print('Token retrieved: $authToken');
      } else {
        print('No auth token found in SharedPreferences');
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return headers;
  }

  // Helper method to refresh token
  Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('REFRESH_TOKEN');
    if (refreshToken == null) {
      print('No refresh token available');
      throw ServerException(message: 'No refresh token available');
    }

    print('Attempting to refresh token');
    final response = await client.post(
      Uri.parse('${AppConstants.usersEndpoint}/refreshToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];
      await prefs.setString('TOKEN', newToken);
      await prefs.setString('REFRESH_TOKEN', newRefreshToken);
      print('Token refreshed successfully');
    } else {
      print('Failed to refresh token: ${response.body}');
      await prefs.remove('TOKEN');
      await prefs.remove('REFRESH_TOKEN');
      throw ServerException(
        message: 'Failed to refresh token: ${response.body}',
      );
    }
  }

  // Helper method to make authenticated GET request with retry
  Future<http.Response> _authenticatedGet(
    String url,
    Map<String, String> headers,
  ) async {
    print('Making GET request to: $url');
    final response = await client.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 401) {
      print('Received 401, attempting to refresh token');
      await _refreshToken();
      final newHeaders = await _getHeaders();
      print('Retrying GET request with new token');
      return client.get(Uri.parse(url), headers: newHeaders);
    }
    return response;
  }

  @override
  Future<List<RendezVousModel>> getUpcomingAppointments(
    String doctorId, {
    int limit = 5,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _authenticatedGet(
        '${AppConstants.dashboardEndpoint}/upcoming-appointments?limit=$limit',
        headers,
      );

      if (response.statusCode != 200) {
        print('Failed to fetch upcoming appointments: ${response.body}');
        throw ServerException(
          message: 'Failed to fetch upcoming appointments: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body);
      final appointmentsData =
          jsonData['data']['appointments'] as List<dynamic>;

      return appointmentsData.map((appointment) {
        return RendezVousModel.fromJson(appointment);
      }).toList();
    } catch (e) {
      print('Error getting upcoming appointments: $e');
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to fetch upcoming appointments: $e',
      );
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsCountByStatus(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final response = await _authenticatedGet(
        '${AppConstants.dashboardEndpoint}/appointments-count',
        headers,
      );

      if (response.statusCode != 200) {
        print('Failed to fetch appointment counts: ${response.body}');
        throw ServerException(
          message: 'Failed to fetch appointment counts: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body);
      final statsData = jsonData['data'];

      return {
        'pending': statsData['pending'] ?? 0,
        'accepted': statsData['accepted'] ?? 0,
        'cancelled': statsData['cancelled'] ?? 0,
        'completed': statsData['completed'] ?? 0,
        'total': statsData['total'] ?? 0,
      };
    } catch (e) {
      print('Error getting appointment counts: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch appointment counts: $e');
    }
  }

  @override
  Future<int> getTotalPatientsCount(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final response = await _authenticatedGet(
        '${AppConstants.dashboardEndpoint}/total-patients',
        headers,
      );

      if (response.statusCode != 200) {
        print('Failed to fetch patient count: ${response.body}');
        throw ServerException(
          message: 'Failed to fetch patient count: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body);
      return jsonData['data']['totalPatients'] ?? 0;
    } catch (e) {
      print('Error getting total patients count: $e');
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to fetch total patients count: $e',
      );
    }
  }

  @override
  Future<DashboardStatsModel> getDoctorDashboardStats(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final response = await _authenticatedGet(
        '${AppConstants.dashboardEndpoint}/stats',
        headers,
      );

      if (response.statusCode != 200) {
        print('Failed to fetch dashboard stats: ${response.body}');
        throw ServerException(
          message: 'Failed to fetch dashboard stats: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body);
      final statsData = jsonData['data'];

      final upcomingAppointments = await getUpcomingAppointments(doctorId);

      return DashboardStatsModel.fromJson(
        statsData,
        upcomingAppointments: upcomingAppointments,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch dashboard stats: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDoctorPatients(
    String doctorId, {
    int limit = 10,
    String? lastPatientId,
  }) async {
    try {
      final headers = await _getHeaders();
      String url = '${AppConstants.dashboardEndpoint}/patients?limit=$limit';
      if (lastPatientId != null) {
        url += '&lastPatientId=$lastPatientId';
      }

      final response = await _authenticatedGet(url, headers);

      if (response.statusCode != 200) {
        print('Failed to fetch doctor patients: ${response.body}');
        throw ServerException(
          message: 'Failed to fetch doctor patients: ${response.body}',
        );
      }

      final jsonData = jsonDecode(response.body);
      final patientsData = jsonData['data']['patients'] as List<dynamic>;

      List<Map<String, dynamic>> formattedPatients =
          patientsData.map((patient) {
            return {
              'id': patient['id'] ?? '',
              'name': patient['name'] ?? '',
              'lastName': patient['lastName'] ?? '',
              'email': patient['email'] ?? '',
              'phoneNumber': patient['phoneNumber'] ?? '',
              'lastAppointment':
                  patient['lastAppointment'] ??
                  DateTime.now().toIso8601String(),
              'lastAppointmentStatus':
                  patient['lastAppointmentStatus'] ?? 'unknown',
            };
          }).toList();

      return {
        'patients': formattedPatients,
        'hasMore': jsonData['data']['hasMore'] ?? false,
        'nextPatientId': jsonData['data']['nextPatientId'],
      };
    } catch (e) {
      print('Error getting doctor patients: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch doctor patients: $e');
    }
  }
}
