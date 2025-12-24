import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/ordonnance/domain/entities/prescription_entity.dart';
import 'package:medical_app/features/ordonnance/data/models/prescription_model.dart';
import 'package:medical_app/core/services/api_service.dart';

abstract class PrescriptionRemoteDataSource {
  Future<PrescriptionModel> createPrescription(PrescriptionEntity prescription);
  Future<PrescriptionModel> editPrescription(PrescriptionEntity prescription);
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId);
  Future<List<PrescriptionModel>> getDoctorPrescriptions(String doctorId);
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId);
  Future<PrescriptionModel?> getPrescriptionByAppointmentId(
    String appointmentId,
  );
  Future<void> updatePrescriptionStatus(String prescriptionId, String status);
}

class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  PrescriptionRemoteDataSourceImpl();

  @override
  Future<PrescriptionModel> createPrescription(
    PrescriptionEntity prescription,
  ) async {
    try {
      final prescriptionData = {
        'consultationId': prescription.consultationId,
        'patientId': prescription.patientId,
        'doctorId': prescription.doctorId,
        'medications':
            prescription.medications.map((med) => med.toJson()).toList(),
        if (prescription.generalInstructions != null)
          'generalInstructions': prescription.generalInstructions,
        if (prescription.specialWarnings != null)
          'specialWarnings': prescription.specialWarnings,
        if (prescription.pharmacyName != null)
          'pharmacyName': prescription.pharmacyName,
        if (prescription.pharmacyAddress != null)
          'pharmacyAddress': prescription.pharmacyAddress,
      };

      final response = await ApiService.postRequest(
        '${ApiService.baseUrl}/prescriptions',
        prescriptionData,
      );

      if (response == null ||
          response['data'] == null ||
          response['data']['prescription'] == null) {
        throw ServerException(
          message: 'Failed to create prescription: Invalid response format',
        );
      }

      return PrescriptionModel.fromJson(response['data']['prescription']);
    } catch (e) {
      throw ServerException(message: 'Failed to create prescription: $e');
    }
  }

  @override
  Future<PrescriptionModel> editPrescription(
    PrescriptionEntity prescription,
  ) async {
    try {
      final prescriptionData = {
        'medications':
            prescription.medications.map((med) => med.toJson()).toList(),
        if (prescription.generalInstructions != null)
          'generalInstructions': prescription.generalInstructions,
        if (prescription.specialWarnings != null)
          'specialWarnings': prescription.specialWarnings,
        if (prescription.pharmacyName != null)
          'pharmacyName': prescription.pharmacyName,
        if (prescription.pharmacyAddress != null)
          'pharmacyAddress': prescription.pharmacyAddress,
      };

      final response = await ApiService.patchRequest(
        '${ApiService.baseUrl}/prescriptions/${prescription.id}',
        prescriptionData,
      );

      if (response == null ||
          response['data'] == null ||
          response['data']['prescription'] == null) {
        throw ServerException(
          message: 'Failed to edit prescription: Invalid response format',
        );
      }

      return PrescriptionModel.fromJson(response['data']['prescription']);
    } catch (e) {
      throw ServerException(message: 'Failed to edit prescription: $e');
    }
  }

  @override
  Future<List<PrescriptionModel>> getPatientPrescriptions(
    String patientId,
  ) async {
    try {
      final response = await ApiService.getRequest(
        '${ApiService.baseUrl}/prescriptions/patient/$patientId',
      );

      if (response == null ||
          response['data'] == null ||
          response['data']['prescriptions'] == null) {
        throw ServerException(
          message:
              'Failed to fetch patient prescriptions: Invalid response format',
        );
      }

      final prescriptionsData = response['data']['prescriptions'] as List;
      return prescriptionsData
          .map(
            (prescriptionData) => PrescriptionModel.fromJson(prescriptionData),
          )
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch patient prescriptions: $e',
      );
    }
  }

  @override
  Future<List<PrescriptionModel>> getDoctorPrescriptions(
    String doctorId,
  ) async {
    try {
      final response = await ApiService.getRequest(
        '${ApiService.baseUrl}/prescriptions/doctor/$doctorId',
      );

      if (response == null ||
          response['data'] == null ||
          response['data']['prescriptions'] == null) {
        throw ServerException(
          message:
              'Failed to fetch doctor prescriptions: Invalid response format',
        );
      }

      final prescriptionsData = response['data']['prescriptions'] as List;
      return prescriptionsData
          .map(
            (prescriptionData) => PrescriptionModel.fromJson(prescriptionData),
          )
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch doctor prescriptions: $e',
      );
    }
  }

  @override
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId) async {
    try {
      final response = await ApiService.getRequest(
        '${ApiService.baseUrl}/prescriptions/$prescriptionId',
      );

      if (response == null ||
          response['data'] == null ||
          response['data']['prescription'] == null) {
        throw ServerException(
          message: 'Failed to fetch prescription: Invalid response format',
        );
      }

      return PrescriptionModel.fromJson(response['data']['prescription']);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch prescription: $e');
    }
  }

  @override
  Future<PrescriptionModel?> getPrescriptionByAppointmentId(
    String appointmentId,
  ) async {
    try {
      final response = await ApiService.getRequest(
        '${ApiService.baseUrl}/prescriptions/appointment/$appointmentId',
      );

      if (response == null || response['data'] == null) {
        throw ServerException(
          message:
              'Failed to fetch prescription by appointment: Invalid response format',
        );
      }

      if (response['data']['prescription'] == null) {
        return null;
      }

      return PrescriptionModel.fromJson(response['data']['prescription']);
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch prescription by appointment: $e',
      );
    }
  }

  @override
  Future<void> updatePrescriptionStatus(
    String prescriptionId,
    String status,
  ) async {
    try {
      await ApiService.patchRequest(
        '${ApiService.baseUrl}/prescriptions/status/$prescriptionId',
        {'status': status},
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to update prescription status: $e',
      );
    }
  }
}
