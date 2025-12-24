import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/medical_records/data/models/consultation_model.dart';
import 'package:medical_app/features/medical_records/data/models/medical_document_model.dart';
import 'package:path/path.dart' as path;

/// Remote data source for medical records operations
abstract class MedicalRecordsRemoteDataSource {
  // Consultation operations
  Future<ConsultationModel> createConsultation({
    required String token,
    required Map<String, dynamic> consultationData,
  });

  Future<ConsultationModel> getConsultationById({
    required String token,
    required String consultationId,
  });

  Future<ConsultationModel> updateConsultation({
    required String token,
    required String consultationId,
    required Map<String, dynamic> updateData,
  });

  Future<ConsultationModel> getConsultationFullDetails({
    required String token,
    required String consultationId,
  });

  Future<List<TimelineEventModel>> getPatientTimeline({
    required String token,
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
    String? filterDoctorId,
    int page = 1,
    int limit = 20,
  });

  Future<List<ConsultationModel>> searchPatientHistory({
    required String token,
    required String patientId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<ConsultationModel>> getDoctorConsultations({
    required String token,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  Future<List<ConsultationModel>> getMyMedicalHistory({
    required String token,
    int page = 1,
    int limit = 20,
  });

  Future<ConsultationStatisticsModel> getConsultationStatistics({
    required String token,
  });

  // Document operations
  Future<MedicalDocumentModel> uploadDocument({
    required String token,
    required File file,
    required String documentType,
    required String title,
    String? description,
    String? consultationId,
    DateTime? documentDate,
    List<String>? tags,
  });

  Future<MedicalDocumentModel> getDocumentById({
    required String token,
    required String documentId,
  });

  Future<List<MedicalDocumentModel>> getPatientDocuments({
    required String token,
    required String patientId,
    String? documentType,
    int page = 1,
    int limit = 20,
  });

  Future<List<MedicalDocumentModel>> getMyDocuments({
    required String token,
    String? documentType,
    int page = 1,
    int limit = 20,
  });

  Future<List<MedicalDocumentModel>> getConsultationDocuments({
    required String token,
    required String consultationId,
  });

  Future<MedicalDocumentModel> updateDocument({
    required String token,
    required String documentId,
    String? title,
    String? description,
    List<String>? tags,
  });

  Future<void> deleteDocument({
    required String token,
    required String documentId,
  });

  Future<String> downloadDocument({
    required String token,
    required String documentId,
  });

  Future<MedicalDocumentModel> updateDocumentSharing({
    required String token,
    required String documentId,
    bool? isSharedWithAllDoctors,
    List<String>? sharedWithDoctors,
  });

  Future<DocumentStatisticsModel> getDocumentStatistics({
    required String token,
  });
}

class MedicalRecordsRemoteDataSourceImpl
    implements MedicalRecordsRemoteDataSource {
  final http.Client client;

  MedicalRecordsRemoteDataSourceImpl({required this.client});

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

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // ==================== CONSULTATION OPERATIONS ====================

  @override
  Future<ConsultationModel> createConsultation({
    required String token,
    required Map<String, dynamic> consultationData,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(AppConstants.consultationsEndpoint),
        headers: _getHeaders(token),
        body: jsonEncode(consultationData),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ConsultationModel.fromJson(
          data['data']?['consultation'] ?? data['consultation'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ConsultationModel> getConsultationById({
    required String token,
    required String consultationId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.consultationsEndpoint}/$consultationId'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ConsultationModel.fromJson(
          data['data']?['consultation'] ?? data['consultation'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ConsultationModel> updateConsultation({
    required String token,
    required String consultationId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('${AppConstants.consultationsEndpoint}/$consultationId'),
        headers: _getHeaders(token),
        body: jsonEncode(updateData),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ConsultationModel.fromJson(
          data['data']?['consultation'] ?? data['consultation'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ConsultationModel> getConsultationFullDetails({
    required String token,
    required String consultationId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.consultationsEndpoint}/$consultationId/full'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ConsultationModel.fromJson(
          data['data']?['consultation'] ?? data['consultation'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimelineEventModel>> getPatientTimeline({
    required String token,
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
    String? filterDoctorId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (filterDoctorId != null) 'doctorId': filterDoctorId,
      };

      final uri = Uri.parse(
              '${AppConstants.patientMedicalHistoryEndpoint}/$patientId/timeline')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final events = data['data']?['timeline'] ?? data['timeline'] ?? [];
      return (events as List)
          .map((e) => TimelineEventModel.fromJson(e))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ConsultationModel>> searchPatientHistory({
    required String token,
    required String patientId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (query != null) 'query': query,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse(
              '${AppConstants.patientMedicalHistoryEndpoint}/$patientId/search')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final consultations =
          data['data']?['consultations'] ?? data['consultations'] ?? [];
      return (consultations as List)
          .map((c) => ConsultationModel.fromJson(c))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ConsultationModel>> getDoctorConsultations({
    required String token,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri =
          Uri.parse('${AppConstants.patientMedicalHistoryEndpoint}/doctors/my-consultations')
              .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final consultations =
          data['data']?['consultations'] ?? data['consultations'] ?? [];
      return (consultations as List)
          .map((c) => ConsultationModel.fromJson(c))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ConsultationModel>> getMyMedicalHistory({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri =
          Uri.parse('${AppConstants.patientMedicalHistoryEndpoint}/my-history')
              .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final consultations =
          data['data']?['consultations'] ?? data['consultations'] ?? [];
      return (consultations as List)
          .map((c) => ConsultationModel.fromJson(c))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ConsultationStatisticsModel> getConsultationStatistics({
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.patientMedicalHistoryEndpoint}/statistics/consultations'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return ConsultationStatisticsModel.fromJson(
          data['data']?['statistics'] ?? data['statistics'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // ==================== DOCUMENT OPERATIONS ====================

  @override
  Future<MedicalDocumentModel> uploadDocument({
    required String token,
    required File file,
    required String documentType,
    required String title,
    String? description,
    String? consultationId,
    DateTime? documentDate,
    List<String>? tags,
  }) async {
    try {
      final fileExtension = path.extension(file.path).replaceAll('.', '');
      final mimeType = _getMimeType(fileExtension);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.medicalDocumentsEndpoint}/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      request.fields['documentType'] = documentType;
      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (consultationId != null) {
        request.fields['consultationId'] = consultationId;
      }
      if (documentDate != null) {
        request.fields['documentDate'] = documentDate.toIso8601String();
      }
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = jsonEncode(tags);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _handleError(response);

      final data = jsonDecode(response.body);
      return MedicalDocumentModel.fromJson(
          data['data']?['document'] ?? data['document'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MedicalDocumentModel> getDocumentById({
    required String token,
    required String documentId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.medicalDocumentsEndpoint}/$documentId'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return MedicalDocumentModel.fromJson(
          data['data']?['document'] ?? data['document'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MedicalDocumentModel>> getPatientDocuments({
    required String token,
    required String patientId,
    String? documentType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (documentType != null) 'documentType': documentType,
      };

      final uri = Uri.parse(
              '${AppConstants.medicalDocumentsEndpoint}/patient/$patientId')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final documents = data['data']?['documents'] ?? data['documents'] ?? [];
      return (documents as List)
          .map((d) => MedicalDocumentModel.fromJson(d))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MedicalDocumentModel>> getMyDocuments({
    required String token,
    String? documentType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (documentType != null) 'documentType': documentType,
      };

      final uri =
          Uri.parse('${AppConstants.medicalDocumentsEndpoint}/my-documents')
              .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final documents = data['data']?['documents'] ?? data['documents'] ?? [];
      return (documents as List)
          .map((d) => MedicalDocumentModel.fromJson(d))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MedicalDocumentModel>> getConsultationDocuments({
    required String token,
    required String consultationId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(
            '${AppConstants.consultationsEndpoint}/$consultationId/documents'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      final documents = data['data']?['documents'] ?? data['documents'] ?? [];
      return (documents as List)
          .map((d) => MedicalDocumentModel.fromJson(d))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MedicalDocumentModel> updateDocument({
    required String token,
    required String documentId,
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
      };

      final response = await client.put(
        Uri.parse('${AppConstants.medicalDocumentsEndpoint}/$documentId'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return MedicalDocumentModel.fromJson(
          data['data']?['document'] ?? data['document'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteDocument({
    required String token,
    required String documentId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('${AppConstants.medicalDocumentsEndpoint}/$documentId'),
        headers: _getHeaders(token),
      );

      _handleError(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> downloadDocument({
    required String token,
    required String documentId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(
            '${AppConstants.medicalDocumentsEndpoint}/$documentId/download'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return data['data']?['downloadUrl'] ?? data['downloadUrl'] ?? '';
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MedicalDocumentModel> updateDocumentSharing({
    required String token,
    required String documentId,
    bool? isSharedWithAllDoctors,
    List<String>? sharedWithDoctors,
  }) async {
    try {
      final body = <String, dynamic>{
        if (isSharedWithAllDoctors != null)
          'isSharedWithAllDoctors': isSharedWithAllDoctors,
        if (sharedWithDoctors != null) 'sharedWithDoctors': sharedWithDoctors,
      };

      final response = await client.put(
        Uri.parse(
            '${AppConstants.medicalDocumentsEndpoint}/$documentId/sharing'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return MedicalDocumentModel.fromJson(
          data['data']?['document'] ?? data['document'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<DocumentStatisticsModel> getDocumentStatistics({
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.medicalDocumentsEndpoint}/statistics'),
        headers: _getHeaders(token),
      );

      _handleError(response);

      final data = jsonDecode(response.body);
      return DocumentStatisticsModel.fromJson(
          data['data']?['statistics'] ?? data['statistics'] ?? data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
