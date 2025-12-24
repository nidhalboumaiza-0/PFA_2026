import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/services/api_service.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import '../models/RendezVous.dart';

abstract class RendezVousRemoteDataSource {
  Future<List<RendezVousModel>> getRendezVous({
    String? patientId,
    String? doctorId,
  });

  Future<void> updateRendezVousStatus(String rendezVousId, String status);

  Future<void> createRendezVous(RendezVousModel rendezVous);

  Future<List<MedecinEntity>> getDoctorsBySpecialty(
    String specialty, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<RendezVousModel> getRendezVousDetails(String rendezVousId);

  Future<void> cancelAppointment(String rendezVousId, {String? reason});

  Future<void> rateDoctor(String appointmentId, double rating);

  Future<List<RendezVousModel>> getDoctorAppointmentsForDay(
    String doctorId,
    DateTime date,
  );

  Future<void> acceptAppointment(String rendezVousId, {String? notes});

  Future<void> refuseAppointment(String rendezVousId, {String? reason});

  Future<void> completeAppointment(String rendezVousId);

  Future<List<RendezVousModel>> getAppointmentRequests();

  Future<Map<String, dynamic>> getDoctorAvailability();

  Future<void> setDoctorAvailability(Map<String, dynamic> availability);

  Future<Map<String, dynamic>> viewDoctorAvailability(String doctorId, {DateTime? date});

  Future<Map<String, dynamic>> getAppointmentStatistics();

  // ==================== RESCHEDULE METHODS ====================
  
  /// Doctor: Reschedule appointment directly
  Future<void> rescheduleAppointment(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Patient: Request to reschedule
  Future<void> requestReschedule(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Doctor: Approve reschedule request
  Future<void> approveReschedule(String appointmentId);

  /// Doctor: Reject reschedule request
  Future<void> rejectReschedule(String appointmentId, {String? reason});
}

class RendezVousRemoteDataSourceImpl implements RendezVousRemoteDataSource {
  final RendezVousLocalDataSource localDataSource;

  RendezVousRemoteDataSourceImpl({required this.localDataSource});

  @override
  Future<List<RendezVousModel>> getRendezVous({
    String? patientId,
    String? doctorId,
  }) async {
    if (patientId == null && doctorId == null) {
      throw ServerException(
        message: 'Either patientId or doctorId must be provided',
      );
    }

    try {
      String url;
      if (patientId != null) {
        // Patient: GET /appointments/patient/my-appointments
        url = '${AppConstants.appointmentsEndpoint}/patient/my-appointments';
      } else {
        // Doctor: GET /appointments/doctor/my-appointments
        url = '${AppConstants.appointmentsEndpoint}/doctor/my-appointments';
      }

      final response = await ApiService.getRequest(url);
      final appointmentsData = response['appointments'] as List? ?? 
                               response['data']?['appointments'] as List? ?? [];

      final rendezVous = appointmentsData
          .map((appointment) => RendezVousModel.fromJson(appointment))
          .toList();
      
      await localDataSource.cacheRendezVous(rendezVous);
      return rendezVous;
    } catch (e) {
      throw ServerException(message: 'Error fetching appointments: $e');
    }
  }

  @override
  Future<void> updateRendezVousStatus(
      String rendezVousId,
      String status,
      ) async {
    try {
      String endpoint;
      Map<String, dynamic> body = {};
      
      switch (status) {
        case 'Accepté':
        case 'confirmed':
          // PUT /appointments/:appointmentId/confirm
          endpoint = '${AppConstants.appointmentsEndpoint}/$rendezVousId/confirm';
          break;
        case 'Refusé':
        case 'rejected':
          // PUT /appointments/:appointmentId/reject
          endpoint = '${AppConstants.appointmentsEndpoint}/$rendezVousId/reject';
          break;
        case 'Annulé':
        case 'cancelled':
          // PUT /appointments/:appointmentId/cancel
          endpoint = '${AppConstants.appointmentsEndpoint}/$rendezVousId/cancel';
          break;
        case 'Terminé':
        case 'completed':
          // PUT /appointments/:appointmentId/complete
          endpoint = '${AppConstants.appointmentsEndpoint}/$rendezVousId/complete';
          break;
        default:
          throw ServerException(message: 'Unsupported status: $status');
      }

      await ApiService.putRequest(endpoint, body);
    } catch (e) {
      throw ServerException(message: 'Error updating appointment status: $e');
    }
  }

  @override
  Future<void> createRendezVous(RendezVousModel rendezVous) async {
    try {
      // POST /appointments/request
      final data = {
        'doctorId': rendezVous.medecin,
        'appointmentDate': rendezVous.startDate.toIso8601String().split('T')[0],
        'appointmentTime': '${rendezVous.startDate.hour.toString().padLeft(2, '0')}:${rendezVous.startDate.minute.toString().padLeft(2, '0')}',
        'reason': rendezVous.motif ?? rendezVous.serviceName,
        if (rendezVous.notes != null) 'notes': rendezVous.notes,
      };

      await ApiService.postRequest(
        '${AppConstants.appointmentsEndpoint}/request',
        data,
      );
    } catch (e) {
      throw ServerException(message: 'Error creating appointment: $e');
    }
  }

  @override
  Future<List<MedecinEntity>> getDoctorsBySpecialty(
    String specialty, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use user-service endpoint for searching doctors
      String url = '${AppConstants.getAllDoctorsEndpoint}?specialty=$specialty';
      
      final response = await ApiService.getRequest(url);
      final doctorsData = response['doctors'] as List? ?? 
                          response['data']?['doctors'] as List? ?? [];

      List<MedecinEntity> doctorEntities = [];
      for (var doctor in doctorsData) {
        MedecinModel doctorModel = MedecinModel.fromJson(doctor);
        doctorEntities.add(doctorModel.toEntity());
      }

      return doctorEntities;
    } catch (e) {
      throw ServerException(message: 'Error fetching doctors by specialty: $e');
    }
  }

  @override
  Future<RendezVousModel> getRendezVousDetails(String rendezVousId) async {
    try {
      // GET /appointments/:appointmentId
      final response = await ApiService.getRequest(
        '${AppConstants.appointmentsEndpoint}/$rendezVousId',
      );

      final appointmentData = response['appointment'] ?? response['data']?['appointment'] ?? response;
      return RendezVousModel.fromJson(appointmentData);
    } catch (e) {
      throw ServerException(message: 'Error fetching appointment details: $e');
    }
  }

  @override
  Future<void> cancelAppointment(String rendezVousId, {String? reason}) async {
    try {
      // PUT /appointments/:appointmentId/cancel
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$rendezVousId/cancel',
        {
          if (reason != null) 'cancellationReason': reason,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error canceling appointment: $e');
    }
  }

  @override
  Future<void> rateDoctor(String appointmentId, double rating) async {
    try {
      // This would be handled by a ratings service
      await ApiService.postRequest(
        '${AppConstants.ratingsEndpoint}',
        {'appointmentId': appointmentId, 'rating': rating},
      );
    } catch (e) {
      throw ServerException(message: 'Error rating doctor: $e');
    }
  }

  @override
  Future<List<RendezVousModel>> getDoctorAppointmentsForDay(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // GET /appointments/doctor/my-appointments?date=YYYY-MM-DD
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await ApiService.getRequest(
        '${AppConstants.appointmentsEndpoint}/doctor/my-appointments?date=$dateStr',
      );

      final appointmentsData = response['appointments'] as List? ?? 
                               response['data']?['appointments'] as List? ?? [];

      return appointmentsData
          .map((appointment) => RendezVousModel.fromJson(appointment))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Error fetching doctor appointments for day: $e',
      );
    }
  }

  @override
  Future<void> acceptAppointment(String rendezVousId, {String? notes}) async {
    try {
      // PUT /appointments/:appointmentId/confirm
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$rendezVousId/confirm',
        {
          if (notes != null) 'notes': notes,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error accepting appointment: $e');
    }
  }

  @override
  Future<void> refuseAppointment(String rendezVousId, {String? reason}) async {
    try {
      // PUT /appointments/:appointmentId/reject
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$rendezVousId/reject',
        {
          if (reason != null) 'rejectionReason': reason,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error refusing appointment: $e');
    }
  }

  @override
  Future<void> completeAppointment(String rendezVousId) async {
    try {
      // PUT /appointments/:appointmentId/complete
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$rendezVousId/complete',
        {},
      );
    } catch (e) {
      throw ServerException(message: 'Error completing appointment: $e');
    }
  }

  @override
  Future<List<RendezVousModel>> getAppointmentRequests() async {
    try {
      // GET /appointments/doctor/requests
      final response = await ApiService.getRequest(
        '${AppConstants.appointmentsEndpoint}/doctor/requests',
      );

      final appointmentsData = response['appointments'] as List? ?? 
                               response['data']?['appointments'] as List? ?? [];

      return appointmentsData
          .map((appointment) => RendezVousModel.fromJson(appointment))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Error fetching appointment requests: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDoctorAvailability() async {
    try {
      // GET /appointments/doctor/availability
      final response = await ApiService.getRequest(
        '${AppConstants.appointmentsEndpoint}/doctor/availability',
      );

      return response['availability'] ?? response['data']?['availability'] ?? {};
    } catch (e) {
      throw ServerException(message: 'Error fetching doctor availability: $e');
    }
  }

  @override
  Future<void> setDoctorAvailability(Map<String, dynamic> availability) async {
    try {
      // POST /appointments/doctor/availability
      await ApiService.postRequest(
        '${AppConstants.appointmentsEndpoint}/doctor/availability',
        availability,
      );
    } catch (e) {
      throw ServerException(message: 'Error setting doctor availability: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> viewDoctorAvailability(String doctorId, {DateTime? date}) async {
    try {
      // GET /appointments/doctors/:doctorId/availability
      String url = '${AppConstants.appointmentsEndpoint}/doctors/$doctorId/availability';
      if (date != null) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '?date=$dateStr';
      }
      
      final response = await ApiService.getRequest(url);

      return response['availability'] ?? response['data']?['availability'] ?? response;
    } catch (e) {
      throw ServerException(message: 'Error fetching doctor availability: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAppointmentStatistics() async {
    try {
      // GET /appointments/doctor/statistics
      final response = await ApiService.getRequest(
        '${AppConstants.appointmentsEndpoint}/doctor/statistics',
      );

      return response['statistics'] ?? response['data']?['statistics'] ?? response;
    } catch (e) {
      throw ServerException(message: 'Error fetching appointment statistics: $e');
    }
  }

  // ==================== RESCHEDULE METHODS ====================

  @override
  Future<void> rescheduleAppointment(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    try {
      // PUT /appointments/:appointmentId/reschedule
      final dateStr = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$appointmentId/reschedule',
        {
          'newDate': dateStr,
          'newTime': newTime,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error rescheduling appointment: $e');
    }
  }

  @override
  Future<void> requestReschedule(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    try {
      // PUT /appointments/:appointmentId/request-reschedule
      final dateStr = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$appointmentId/request-reschedule',
        {
          'newDate': dateStr,
          'newTime': newTime,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error requesting reschedule: $e');
    }
  }

  @override
  Future<void> approveReschedule(String appointmentId) async {
    try {
      // PUT /appointments/:appointmentId/approve-reschedule
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$appointmentId/approve-reschedule',
        {},
      );
    } catch (e) {
      throw ServerException(message: 'Error approving reschedule: $e');
    }
  }

  @override
  Future<void> rejectReschedule(String appointmentId, {String? reason}) async {
    try {
      // PUT /appointments/:appointmentId/reject-reschedule
      await ApiService.putRequest(
        '${AppConstants.appointmentsEndpoint}/$appointmentId/reject-reschedule',
        {
          if (reason != null) 'rejectionReason': reason,
        },
      );
    } catch (e) {
      throw ServerException(message: 'Error rejecting reschedule: $e');
    }
  }
}
