import '../../domain/entities/appointment_entity.dart';

/// Data model for Appointment from API
class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.appointmentDate,
    required super.appointmentTime,
    super.duration,
    required super.status,
    super.reason,
    super.notes,
    super.cancellationReason,
    super.cancelledBy,
    super.cancelledAt,
    super.rejectionReason,
    super.rejectedAt,
    super.confirmedAt,
    super.completedAt,
    super.isRescheduled,
    super.rescheduledBy,
    super.rescheduledAt,
    super.previousDate,
    super.previousTime,
    super.rescheduleReason,
    super.rescheduleCount,
    super.rescheduleRequest,
    required super.createdAt,
    required super.updatedAt,
    super.isReferral,
    super.referredBy,
    super.referralId,
    super.patientInfo,
    super.doctorInfo,
    super.referringDoctorInfo,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      appointmentDate: DateTime.parse(json['appointmentDate']),
      appointmentTime: json['appointmentTime'] ?? '',
      duration: json['duration'] ?? 30,
      status: AppointmentStatus.fromString(json['status'] ?? 'pending'),
      reason: json['reason'],
      notes: json['notes'],
      cancellationReason: json['cancellationReason'],
      cancelledBy: json['cancelledBy'],
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isRescheduled: json['isRescheduled'] ?? false,
      rescheduledBy: json['rescheduledBy'],
      rescheduledAt: json['rescheduledAt'] != null
          ? DateTime.parse(json['rescheduledAt'])
          : null,
      previousDate: json['previousDate'] != null
          ? DateTime.parse(json['previousDate'])
          : null,
      previousTime: json['previousTime'],
      rescheduleReason: json['rescheduleReason'],
      rescheduleCount: json['rescheduleCount'] ?? 0,
      rescheduleRequest: json['rescheduleRequest'] != null
          ? RescheduleRequestModel.fromJson(json['rescheduleRequest'])
          : null,
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isReferral: json['isReferral'] ?? false,
      referredBy: json['referredBy']?.toString(),
      referralId: json['referralId']?.toString(),
      patientInfo: json['patientInfo'] != null
          ? PatientInfoModel.fromJson(json['patientInfo'])
          : null,
      doctorInfo: json['doctorInfo'] != null
          ? DoctorInfoModel.fromJson(json['doctorInfo'])
          : null,
      referringDoctorInfo: json['referringDoctorInfo'] != null
          ? DoctorInfoModel.fromJson(json['referringDoctorInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'duration': duration,
        'status': status.name,
        'reason': reason,
        'notes': notes,
        'isReferral': isReferral,
        'referredBy': referredBy,
        'referralId': referralId,
      };
}

class RescheduleRequestModel extends RescheduleRequest {
  const RescheduleRequestModel({
    super.requestedDate,
    super.requestedTime,
    super.reason,
    super.requestedAt,
    super.status,
  });

  factory RescheduleRequestModel.fromJson(Map<String, dynamic> json) {
    return RescheduleRequestModel(
      requestedDate: json['requestedDate'] != null
          ? DateTime.parse(json['requestedDate'])
          : null,
      requestedTime: json['requestedTime'],
      reason: json['reason'],
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : null,
      status: json['status'],
    );
  }
}

class PatientInfoModel extends PatientInfo {
  const PatientInfoModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.profilePhoto,
  });

  factory PatientInfoModel.fromJson(Map<String, dynamic> json) {
    return PatientInfoModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePhoto: json['profilePhoto'],
    );
  }
}

class DoctorInfoModel extends DoctorInfo {
  const DoctorInfoModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.specialty,
    super.profilePhoto,
    super.clinicName,
    super.rating,
    super.reviewCount,
  });

  factory DoctorInfoModel.fromJson(Map<String, dynamic> json) {
    return DoctorInfoModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      specialty: json['specialty'] ?? 'General Practice',
      profilePhoto: json['profilePhoto'],
      clinicName: json['clinicName'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
    );
  }
}
