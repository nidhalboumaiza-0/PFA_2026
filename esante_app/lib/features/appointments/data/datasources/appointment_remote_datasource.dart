import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../presentation/bloc/doctor/doctor_appointment_bloc.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';

abstract class AppointmentRemoteDataSource {
  // Patient operations
  Future<List<TimeSlotModel>> viewDoctorAvailability({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<AppointmentModel> requestAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? reason,
    String? notes,
  });

  Future<AppointmentModel> cancelAppointment({
    required String appointmentId,
    required String reason,
  });

  Future<AppointmentModel> requestReschedule({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  Future<List<AppointmentModel>> getPatientAppointments({
    String? status,
    int page,
    int limit,
  });

  // Doctor operations
  Future<TimeSlotModel> setAvailability({
    required DateTime date,
    required List<String> timeSlots,
    String? specialNotes,
  });

  Future<Map<String, dynamic>> bulkSetAvailability({
    required List<AvailabilityEntry> availabilities,
    bool skipExisting = true,
  });

  Future<List<TimeSlotModel>> getDoctorAvailability({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<AppointmentModel>> getAppointmentRequests({
    int page,
    int limit,
  });

  Future<AppointmentModel> confirmAppointment({required String appointmentId});
  Future<AppointmentModel> rejectAppointment({
    required String appointmentId,
    required String reason,
  });

  Future<AppointmentModel> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  Future<AppointmentModel> approveReschedule({required String appointmentId});
  Future<AppointmentModel> rejectReschedule({
    required String appointmentId,
    String? reason,
  });

  Future<AppointmentModel> completeAppointment({
    required String appointmentId,
    String? notes,
  });

  Future<List<AppointmentModel>> getDoctorAppointments({
    String? status,
    DateTime? date,
    int page,
    int limit,
  });

  Future<AppointmentStatistics> getAppointmentStatistics();

  // Shared
  Future<AppointmentModel> getAppointmentDetails({required String appointmentId});
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final ApiClient _apiClient;

  AppointmentRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[AppointmentRemoteDataSource.$method] $message');
  }

  // ============== Patient Operations ==============

  @override
  Future<List<TimeSlotModel>> viewDoctorAvailability({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _log('viewDoctorAvailability', 'Getting availability for doctor: $doctorId');

    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _apiClient.get(
      ApiList.appointmentDoctorAvailability(doctorId),
      queryParameters: queryParams,
    );

    final slots = (response['availability'] as List<dynamic>?)
            ?.map((s) => TimeSlotModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    _log('viewDoctorAvailability', 'Found ${slots.length} days with availability');
    return slots;
  }

  @override
  Future<AppointmentModel> requestAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? reason,
    String? notes,
  }) async {
    _log('requestAppointment', 'Requesting appointment with doctor: $doctorId');

    final response = await _apiClient.post(
      ApiList.appointmentRequest,
      data: {
        'doctorId': doctorId,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        if (reason != null) 'reason': reason,
        if (notes != null) 'notes': notes,
      },
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    _log('cancelAppointment', 'Cancelling appointment: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentCancel(appointmentId),
      data: {'cancellationReason': reason},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> requestReschedule({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    _log('requestReschedule', 'Requesting reschedule for: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentRequestReschedule(appointmentId),
      data: {
        'newDate': newDate.toIso8601String(),
        'newTime': newTime,
        if (reason != null) 'reason': reason,
      },
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<List<AppointmentModel>> getPatientAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    _log('getPatientAppointments', 'Fetching patient appointments');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiList.patientAppointments,
      queryParameters: queryParams,
    );

    return (response['appointments'] as List<dynamic>?)
            ?.map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];
  }

  // ============== Doctor Operations ==============

  @override
  Future<TimeSlotModel> setAvailability({
    required DateTime date,
    required List<String> timeSlots,
    String? specialNotes,
  }) async {
    _log('setAvailability', 'Setting availability for: ${date.toIso8601String()}');

    final response = await _apiClient.post(
      ApiList.doctorSetAvailability,
      data: {
        'date': date.toIso8601String(),
        'slots': timeSlots.map((t) => {'time': t}).toList(),
        if (specialNotes != null) 'specialNotes': specialNotes,
      },
    );

    return TimeSlotModel.fromJson(response['timeSlot']);
  }

  @override
  Future<Map<String, dynamic>> bulkSetAvailability({
    required List<AvailabilityEntry> availabilities,
    bool skipExisting = true,
  }) async {
    _log('bulkSetAvailability', 'Setting bulk availability for ${availabilities.length} dates');

    final response = await _apiClient.post(
      ApiList.doctorBulkSetAvailability,
      data: {
        'availabilities': availabilities.map((a) => a.toJson()).toList(),
        'skipExisting': skipExisting,
      },
    );

    return response['results'] as Map<String, dynamic>? ?? {};
  }

  @override
  Future<List<TimeSlotModel>> getDoctorAvailability({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _log('getDoctorAvailability', 'Fetching doctor availability');

    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _apiClient.get(
      ApiList.doctorGetAvailability,
      queryParameters: queryParams,
    );

    // Backend returns 'timeSlots' field
    return (response['timeSlots'] as List<dynamic>?)
            ?.map((s) => TimeSlotModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<List<AppointmentModel>> getAppointmentRequests({
    int page = 1,
    int limit = 20,
  }) async {
    _log('getAppointmentRequests', 'Fetching appointment requests');

    final response = await _apiClient.get(
      ApiList.doctorAppointmentRequests,
      queryParameters: {'page': page, 'limit': limit},
    );

    return (response['requests'] as List<dynamic>?)
            ?.map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<AppointmentModel> confirmAppointment({
    required String appointmentId,
  }) async {
    _log('confirmAppointment', 'Confirming: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentConfirm(appointmentId),
      data: {},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> rejectAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    _log('rejectAppointment', 'Rejecting: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentReject(appointmentId),
      data: {'rejectionReason': reason},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    _log('rescheduleAppointment', 'Rescheduling: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentReschedule(appointmentId),
      data: {
        'newDate': newDate.toIso8601String(),
        'newTime': newTime,
        if (reason != null) 'reason': reason,
      },
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> approveReschedule({
    required String appointmentId,
  }) async {
    _log('approveReschedule', 'Approving reschedule: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentApproveReschedule(appointmentId),
      data: {},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> rejectReschedule({
    required String appointmentId,
    String? reason,
  }) async {
    _log('rejectReschedule', 'Rejecting reschedule: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentRejectReschedule(appointmentId),
      data: {if (reason != null) 'reason': reason},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<AppointmentModel> completeAppointment({
    required String appointmentId,
    String? notes,
  }) async {
    _log('completeAppointment', 'Completing: $appointmentId');

    final response = await _apiClient.put(
      ApiList.appointmentComplete(appointmentId),
      data: {if (notes != null) 'notes': notes},
    );

    return AppointmentModel.fromJson(response['appointment']);
  }

  @override
  Future<List<AppointmentModel>> getDoctorAppointments({
    String? status,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    _log('getDoctorAppointments', 'Fetching doctor appointments');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date.toIso8601String();

    final response = await _apiClient.get(
      ApiList.doctorAppointments,
      queryParameters: queryParams,
    );

    return (response['appointments'] as List<dynamic>?)
            ?.map((a) => AppointmentModel.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<AppointmentStatistics> getAppointmentStatistics() async {
    _log('getAppointmentStatistics', 'Fetching statistics');

    final response = await _apiClient.get(ApiList.doctorStatistics);

    final stats = response['statistics'] as Map<String, dynamic>?;
    if (stats == null) return const AppointmentStatistics();

    return AppointmentStatistics(
      totalAppointments: stats['totalAppointments'] ?? 0,
      pendingCount: stats['pendingCount'] ?? 0,
      confirmedCount: stats['confirmedCount'] ?? 0,
      completedCount: stats['completedCount'] ?? 0,
      cancelledCount: stats['cancelledCount'] ?? 0,
      todayAppointments: stats['todayAppointments'] ?? 0,
      weekAppointments: stats['weekAppointments'] ?? 0,
    );
  }

  // ============== Shared Operations ==============

  @override
  Future<AppointmentModel> getAppointmentDetails({
    required String appointmentId,
  }) async {
    _log('getAppointmentDetails', 'Getting details for: $appointmentId');

    final response = await _apiClient.get(ApiList.appointmentDetails(appointmentId));

    return AppointmentModel.fromJson(response['appointment']);
  }
}
