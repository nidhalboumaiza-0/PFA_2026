import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/medical_history_model.dart';

/// Remote data source for medical records
abstract class MedicalRecordsRemoteDataSource {
  /// Get a patient's medical history (for doctors)
  Future<MedicalHistoryModel> getPatientMedicalHistory({
    required String patientId,
  });

  /// Get current user's own medical history (for patients)
  Future<MedicalHistoryModel> getMyMedicalHistory();
}

class MedicalRecordsRemoteDataSourceImpl
    implements MedicalRecordsRemoteDataSource {
  final ApiClient _apiClient;

  MedicalRecordsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[MedicalRecordsDataSource.$method] $message');
  }

  @override
  Future<MedicalHistoryModel> getPatientMedicalHistory({
    required String patientId,
  }) async {
    _log('getPatientMedicalHistory', 'Fetching history for patient: $patientId');
    try {
      final response = await _apiClient.get(
        ApiList.doctorPatientMedicalHistory(patientId),
      );
      _log('getPatientMedicalHistory', 'Response received');

      // Response may be wrapped in 'data' or directly at root
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return MedicalHistoryModel.fromJson(data);
    } catch (e, stackTrace) {
      _log('getPatientMedicalHistory', 'Error: $e');
      _log('getPatientMedicalHistory', 'StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<MedicalHistoryModel> getMyMedicalHistory() async {
    _log('getMyMedicalHistory', 'Fetching my medical history');
    try {
      final response = await _apiClient.get(
        ApiList.patientMyMedicalHistory,
      );
      _log('getMyMedicalHistory', 'Response received');

      final data = response['data'] as Map<String, dynamic>? ?? response;
      return MedicalHistoryModel.fromJson(data);
    } catch (e, stackTrace) {
      _log('getMyMedicalHistory', 'Error: $e');
      _log('getMyMedicalHistory', 'StackTrace: $stackTrace');
      rethrow;
    }
  }
}
