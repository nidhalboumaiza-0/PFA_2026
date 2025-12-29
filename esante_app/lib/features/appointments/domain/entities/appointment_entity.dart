import 'package:equatable/equatable.dart';

/// Appointment status enum
enum AppointmentStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
  completed,
  noShow;

  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'no-show':
      case 'noshow':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  bool get isActive =>
      this == AppointmentStatus.pending || this == AppointmentStatus.confirmed;

  bool get isFinal =>
      this == AppointmentStatus.rejected ||
      this == AppointmentStatus.cancelled ||
      this == AppointmentStatus.completed ||
      this == AppointmentStatus.noShow;
}

/// Entity representing an appointment
class AppointmentEntity extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int duration; // in minutes
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final bool isRescheduled;
  final String? rescheduledBy;
  final DateTime? rescheduledAt;
  final DateTime? previousDate;
  final String? previousTime;
  final String? rescheduleReason;
  final int rescheduleCount;
  final RescheduleRequest? rescheduleRequest;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional populated data
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.duration = 30,
    required this.status,
    this.reason,
    this.notes,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.rejectionReason,
    this.rejectedAt,
    this.confirmedAt,
    this.completedAt,
    this.isRescheduled = false,
    this.rescheduledBy,
    this.rescheduledAt,
    this.previousDate,
    this.previousTime,
    this.rescheduleReason,
    this.rescheduleCount = 0,
    this.rescheduleRequest,
    required this.createdAt,
    required this.updatedAt,
    this.patientInfo,
    this.doctorInfo,
  });

  String get formattedDateTime {
    final date =
        '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
    return '$date at $appointmentTime';
  }

  bool get canCancel =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get canReschedule => canCancel;

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isActive => status.isActive;
  bool get isFinal => status.isFinal;

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        appointmentDate,
        appointmentTime,
        duration,
        status,
        reason,
        notes,
        cancellationReason,
        cancelledBy,
        cancelledAt,
        rejectionReason,
        rejectedAt,
        confirmedAt,
        completedAt,
        isRescheduled,
        rescheduledBy,
        rescheduledAt,
        previousDate,
        previousTime,
        rescheduleReason,
        rescheduleCount,
        rescheduleRequest,
        createdAt,
        updatedAt,
        patientInfo,
        doctorInfo,
      ];
}

/// Reschedule request info
class RescheduleRequest extends Equatable {
  final DateTime? requestedDate;
  final String? requestedTime;
  final String? reason;
  final DateTime? requestedAt;
  final String? status;

  const RescheduleRequest({
    this.requestedDate,
    this.requestedTime,
    this.reason,
    this.requestedAt,
    this.status,
  });

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props =>
      [requestedDate, requestedTime, reason, requestedAt, status];
}

/// Minimal patient info for display
class PatientInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePhoto;

  const PatientInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, profilePhoto];
}

/// Minimal doctor info for display
class DoctorInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String specialty;
  final String? profilePhoto;
  final String? clinicName;

  const DoctorInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    this.profilePhoto,
    this.clinicName,
  });

  String get fullName => 'Dr. $firstName $lastName';

  @override
  List<Object?> get props =>
      [id, firstName, lastName, specialty, profilePhoto, clinicName];
}
