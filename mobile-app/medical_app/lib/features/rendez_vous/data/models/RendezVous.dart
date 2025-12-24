import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';

class RendezVousModel extends RendezVousEntity {
  RendezVousModel({
    String? id,
    required DateTime startDate,
    required DateTime endDate,
    required String serviceName,
    required String patient,
    required String medecin,
    required String status,
    String? motif,
    String? notes,
    List<String>? symptoms,
    bool isRated = false,
    bool hasPrescription = false,
    DateTime? createdAt,
    // Reschedule fields
    bool isRescheduled = false,
    String? rescheduledBy,
    DateTime? previousDate,
    RescheduleRequest? rescheduleRequest,
    // UI display fields
    String? patientName,
    String? patientLastName,
    String? patientProfilePicture,
    String? patientPhoneNumber,
    String? medecinName,
    String? medecinLastName,
    String? medecinProfilePicture,
    String? medecinSpeciality,
  }) : super(
         id: id,
         startDate: startDate,
         endDate: endDate,
         serviceName: serviceName,
         patient: patient,
         medecin: medecin,
         status: status,
         motif: motif,
         notes: notes,
         symptoms: symptoms,
         isRated: isRated,
         hasPrescription: hasPrescription,
         createdAt: createdAt,
         isRescheduled: isRescheduled,
         rescheduledBy: rescheduledBy,
         previousDate: previousDate,
         rescheduleRequest: rescheduleRequest,
         patientName: patientName,
         patientLastName: patientLastName,
         patientProfilePicture: patientProfilePicture,
         patientPhoneNumber: patientPhoneNumber,
         medecinName: medecinName,
         medecinLastName: medecinLastName,
         medecinProfilePicture: medecinProfilePicture,
         medecinSpeciality: medecinSpeciality,
       );

  /// Map backend status values to app status values
  static String _mapStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Accepté';
      case 'rejected':
        return 'Refusé';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      case 'no-show':
        return 'Absence';
      default:
        return backendStatus;
    }
  }

  /// Map app status values to backend status values
  static String statusToBackend(String appStatus) {
    switch (appStatus) {
      case 'En attente':
        return 'pending';
      case 'Accepté':
        return 'confirmed';
      case 'Refusé':
        return 'rejected';
      case 'Annulé':
        return 'cancelled';
      case 'Terminé':
        return 'completed';
      case 'Absence':
        return 'no-show';
      default:
        return appStatus.toLowerCase();
    }
  }

  /// Parse time string (HH:MM) to hours and minutes
  static List<int> _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return [int.parse(parts[0]), int.parse(parts.length > 1 ? parts[1] : '0')];
  }

  factory RendezVousModel.fromJson(Map<String, dynamic> json) {
    // Backend uses patientId/doctorId or nested patient/doctor objects
    final Map<String, dynamic>? patientData =
        json['patient'] is Map
            ? Map<String, dynamic>.from(json['patient'] as Map)
            : null;

    final Map<String, dynamic>? doctorData =
        json['doctor'] is Map
            ? Map<String, dynamic>.from(json['doctor'] as Map)
            : (json['medecin'] is Map
                ? Map<String, dynamic>.from(json['medecin'] as Map)
                : null);

    // Handle backend date/time format
    DateTime startDate;
    DateTime endDate;
    
    if (json['appointmentDate'] != null) {
      // Backend format: appointmentDate + appointmentTime
      final appointmentDate = DateTime.parse(json['appointmentDate'] as String);
      final timeStr = json['appointmentTime'] as String? ?? '09:00';
      final timeParts = _parseTime(timeStr);
      final duration = json['duration'] as int? ?? 30;
      
      startDate = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        timeParts[0],
        timeParts[1],
      );
      endDate = startDate.add(Duration(minutes: duration));
    } else if (json['startDate'] != null) {
      // Legacy format: startDate + endDate
      startDate = DateTime.parse(json['startDate'] as String);
      endDate = json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : startDate.add(const Duration(minutes: 30));
    } else {
      // Fallback
      startDate = DateTime.now();
      endDate = startDate.add(const Duration(minutes: 30));
    }

    // Get patient ID
    String patientId = '';
    if (json['patientId'] != null) {
      patientId = json['patientId'] is String 
          ? json['patientId'] as String 
          : json['patientId']['_id'] as String? ?? '';
    } else if (json['patient'] != null) {
      patientId = json['patient'] is String
          ? json['patient'] as String
          : patientData?['_id'] as String? ?? '';
    }

    // Get doctor ID
    String doctorId = '';
    if (json['doctorId'] != null) {
      doctorId = json['doctorId'] is String 
          ? json['doctorId'] as String 
          : json['doctorId']['_id'] as String? ?? '';
    } else if (json['doctor'] != null) {
      doctorId = json['doctor'] is String
          ? json['doctor'] as String
          : doctorData?['_id'] as String? ?? '';
    } else if (json['medecin'] != null) {
      doctorId = json['medecin'] is String
          ? json['medecin'] as String
          : doctorData?['_id'] as String? ?? '';
    }

    // Get service name / reason
    String serviceName = json['serviceName'] as String? ??
        json['reason'] as String? ??
        'Consultation';

    return RendezVousModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      startDate: startDate,
      endDate: endDate,
      serviceName: serviceName,
      patient: patientId,
      medecin: doctorId,
      status: _mapStatus(json['status'] as String? ?? 'pending'),
      motif: json['motif'] as String? ?? json['reason'] as String?,
      notes: json['notes'] as String?,
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'] as List)
          : null,
      isRated: json['isRated'] as bool? ?? false,
      hasPrescription: json['hasPrescription'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,

      // Reschedule fields
      isRescheduled: json['isRescheduled'] as bool? ?? false,
      rescheduledBy: json['rescheduledBy'] as String?,
      previousDate: json['previousDate'] != null
          ? DateTime.parse(json['previousDate'] as String)
          : null,
      rescheduleRequest: json['rescheduleRequest'] != null
          ? RescheduleRequest.fromJson(
              Map<String, dynamic>.from(json['rescheduleRequest'] as Map))
          : null,

      // UI display fields from populated patient data
      patientName: patientData?['name'] as String?,
      patientLastName: patientData?['lastName'] as String?,
      patientProfilePicture: patientData?['profilePicture'] as String?,
      patientPhoneNumber: patientData?['phoneNumber'] as String?,

      // UI display fields from populated doctor data
      medecinName: doctorData?['name'] as String?,
      medecinLastName: doctorData?['lastName'] as String?,
      medecinProfilePicture: doctorData?['profilePicture'] as String?,
      medecinSpeciality: doctorData?['speciality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'appointmentDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'appointmentTime': '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
      'duration': endDate.difference(startDate).inMinutes,
      'patientId': patient,
      'doctorId': medecin,
      'status': statusToBackend(status),
      'reason': motif ?? serviceName,
      if (notes != null) 'notes': notes,
      if (symptoms != null) 'symptoms': symptoms,
      'isRated': isRated,
      'hasPrescription': hasPrescription,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Create a copy for backend API calls using backend field names
  Map<String, dynamic> toBackendJson() {
    return {
      'doctorId': medecin,
      'appointmentDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'appointmentTime': '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
      'reason': motif ?? serviceName,
      if (notes != null) 'notes': notes,
    };
  }
}
