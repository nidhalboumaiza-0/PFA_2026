import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../../../../core/error/exceptions.dart';
import '../models/prescription_model.dart';
import '../../domain/usecases/create_prescription.dart';

/// Abstract class defining prescription data source operations
abstract class PrescriptionRemoteDataSource {
  /// Get patient's prescriptions
  Future<List<PrescriptionModel>> getMyPrescriptions({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get prescription by ID
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId);

  /// Create a new prescription
  Future<PrescriptionModel> createPrescription(CreatePrescriptionParams params);
}

/// Implementation of PrescriptionRemoteDataSource
class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  final ApiClient _apiClient;

  PrescriptionRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<PrescriptionModel>> getMyPrescriptions({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiList.patientMyPrescriptions,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null && status != 'all') 'status': status,
        },
      );

      // ApiClient returns Map<String, dynamic> directly
      final prescriptionsList = response['prescriptions'] as List<dynamic>? ?? [];

      return prescriptionsList
          .map((json) => PrescriptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId) async {
    try {
      final response = await _apiClient.get(
        ApiList.prescriptionById(prescriptionId),
      );

      // ApiClient returns Map<String, dynamic> directly
      // Check if prescription is nested or at root level
      final prescriptionData = response['prescription'] as Map<String, dynamic>? ?? response;
      return PrescriptionModel.fromJson(prescriptionData);
    } catch (e) {
      throw ServerException(code: 'SERVER_ERROR', message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PrescriptionModel> createPrescription(CreatePrescriptionParams params) async {
    try {
      final response = await _apiClient.post(
        ApiList.doctorCreatePrescription,
        data: params.toJson(),
      );

      // ApiClient returns Map<String, dynamic> directly
      final prescriptionData = response['prescription'] as Map<String, dynamic>? ?? response;
      return PrescriptionModel.fromJson(prescriptionData);
    } catch (e) {
      throw ServerException(code: 'SERVER_ERROR', message: e.toString(), statusCode: 500);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.statusCode == 404) {
      return Exception('Prescription not found');
    } else if (e.response?.statusCode == 403) {
      return Exception('You do not have access to this prescription');
    }
    return Exception(e.message ?? 'Failed to fetch prescription data');
  }
}
