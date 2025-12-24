import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medical_app/core/services/api_service.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/referral/data/models/referral_model.dart';

// Define the referrals endpoint locally
final String _referralsEndpoint = '${ApiService.baseUrl}/referrals';

/// Remote data source for referral operations
abstract class ReferralRemoteDataSource {
  /// Create a new referral
  Future<ReferralModel> createReferral({
    required String token,
    required String targetDoctorId,
    required String patientId,
    required String reason,
    required String specialty,
    String urgency = 'routine',
    String? diagnosis,
    List<String>? symptoms,
    String? relevantHistory,
    String? currentMedications,
    String? specificConcerns,
    List<String>? attachedDocuments,
    bool includeFullHistory = true,
    List<DateTime>? preferredDates,
    String? referralNotes,
  });

  /// Get referral by ID
  Future<ReferralModel> getReferralById({
    required String token,
    required String referralId,
  });

  /// Search specialists for referral
  Future<List<MedecinModel>> searchSpecialists({
    required String token,
    required String specialty,
    String? city,
    String? name,
  });

  /// Book appointment for referral
  Future<void> bookAppointmentForReferral({
    required String token,
    required String referralId,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  });

  /// Get sent referrals (referring doctor)
  Future<List<ReferralModel>> getSentReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get received referrals (target doctor)
  Future<List<ReferralModel>> getReceivedReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Accept referral
  Future<ReferralModel> acceptReferral({
    required String token,
    required String referralId,
    String? responseNotes,
  });

  /// Reject referral
  Future<ReferralModel> rejectReferral({
    required String token,
    required String referralId,
    required String reason,
  });

  /// Complete referral
  Future<ReferralModel> completeReferral({
    required String token,
    required String referralId,
    String? completionNotes,
  });

  /// Cancel referral
  Future<ReferralModel> cancelReferral({
    required String token,
    required String referralId,
    required String reason,
  });

  /// Get my referrals (patient)
  Future<List<ReferralModel>> getMyReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get referral statistics
  Future<Map<String, dynamic>> getReferralStatistics({
    required String token,
  });
}

class ReferralRemoteDataSourceImpl implements ReferralRemoteDataSource {
  final http.Client client;

  ReferralRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? body['error'] ?? 'Unknown error';
      throw ServerException(message: message);
    }
  }

  @override
  Future<ReferralModel> createReferral({
    required String token,
    required String targetDoctorId,
    required String patientId,
    required String reason,
    required String specialty,
    String urgency = 'routine',
    String? diagnosis,
    List<String>? symptoms,
    String? relevantHistory,
    String? currentMedications,
    String? specificConcerns,
    List<String>? attachedDocuments,
    bool includeFullHistory = true,
    List<DateTime>? preferredDates,
    String? referralNotes,
  }) async {
    try {
      final body = ReferralModel.createReferralRequest(
        targetDoctorId: targetDoctorId,
        patientId: patientId,
        reason: reason,
        specialty: specialty,
        urgency: urgency,
        diagnosis: diagnosis,
        symptoms: symptoms,
        relevantHistory: relevantHistory,
        currentMedications: currentMedications,
        specificConcerns: specificConcerns,
        attachedDocuments: attachedDocuments,
        includeFullHistory: includeFullHistory,
        preferredDates: preferredDates,
        referralNotes: referralNotes,
      );

      final response = await client.post(
        Uri.parse(_referralsEndpoint),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReferralModel> getReferralById({
    required String token,
    required String referralId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$_referralsEndpoint/$referralId'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MedecinModel>> searchSpecialists({
    required String token,
    required String specialty,
    String? city,
    String? name,
  }) async {
    try {
      final queryParams = <String, String>{
        'specialty': specialty,
        if (city != null) 'city': city,
        if (name != null) 'name': name,
      };

      final uri = Uri.parse('$_referralsEndpoint/search-specialists')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final specialists = data['data'] ?? data['specialists'] ?? [];
      return (specialists as List)
          .map((json) => MedecinModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> bookAppointmentForReferral({
    required String token,
    required String referralId,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    try {
      final body = {
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        if (notes != null) 'notes': notes,
      };

      final response = await client.post(
        Uri.parse('$_referralsEndpoint/$referralId/book-appointment'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ReferralModel>> getSentReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': ReferralModel.toBackendStatus(status),
      };

      final uri = Uri.parse('$_referralsEndpoint/sent')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final referrals = data['data'] ?? data['referrals'] ?? [];
      return (referrals as List)
          .map((json) => ReferralModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ReferralModel>> getReceivedReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': ReferralModel.toBackendStatus(status),
      };

      final uri = Uri.parse('$_referralsEndpoint/received')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final referrals = data['data'] ?? data['referrals'] ?? [];
      return (referrals as List)
          .map((json) => ReferralModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReferralModel> acceptReferral({
    required String token,
    required String referralId,
    String? responseNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (responseNotes != null) 'responseNotes': responseNotes,
      };

      final response = await client.put(
        Uri.parse('$_referralsEndpoint/$referralId/accept'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReferralModel> rejectReferral({
    required String token,
    required String referralId,
    required String reason,
  }) async {
    try {
      final body = {'reason': reason};

      final response = await client.put(
        Uri.parse('$_referralsEndpoint/$referralId/reject'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReferralModel> completeReferral({
    required String token,
    required String referralId,
    String? completionNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (completionNotes != null) 'completionNotes': completionNotes,
      };

      final response = await client.put(
        Uri.parse('$_referralsEndpoint/$referralId/complete'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReferralModel> cancelReferral({
    required String token,
    required String referralId,
    required String reason,
  }) async {
    try {
      final body = {'reason': reason};

      final response = await client.put(
        Uri.parse('$_referralsEndpoint/$referralId/cancel'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ReferralModel.fromJson(data['data'] ?? data['referral'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ReferralModel>> getMyReferrals({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': ReferralModel.toBackendStatus(status),
      };

      final uri = Uri.parse('$_referralsEndpoint/my-referrals')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final referrals = data['data'] ?? data['referrals'] ?? [];
      return (referrals as List)
          .map((json) => ReferralModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getReferralStatistics({
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$_referralsEndpoint/statistics'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return data['data'] ?? data['statistics'] ?? data;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
