import 'package:equatable/equatable.dart';

/// Urgency levels for referrals
enum ReferralUrgency { routine, urgent, emergency }

/// Status values for referrals
enum ReferralStatus {
  pending,
  scheduled,
  accepted,
  inProgress,
  completed,
  rejected,
  cancelled
}

/// Status history entry for tracking referral status changes
class StatusHistoryEntry extends Equatable {
  final String status;
  final DateTime changedAt;
  final String? changedBy;
  final String? reason;

  const StatusHistoryEntry({
    required this.status,
    required this.changedAt,
    this.changedBy,
    this.reason,
  });

  @override
  List<Object?> get props => [status, changedAt, changedBy, reason];
}

/// Entity representing a medical referral between doctors
class ReferralEntity extends Equatable {
  final String? id;
  final String referringDoctorId;
  final String targetDoctorId;
  final String patientId;
  final DateTime? referralDate;
  final String reason;
  final String urgency; // String to match backend values
  final String? specialty;
  
  // Medical Context
  final String? diagnosis;
  final List<String>? symptoms;
  final String? relevantHistory;
  final String? currentMedications;
  final String? specificConcerns;
  
  // Attached Documents
  final List<String>? attachedDocuments;
  final bool includeFullHistory;
  
  // Appointment Booking
  final String? appointmentId;
  final bool isAppointmentBooked;
  final List<DateTime>? preferredDates;
  final DateTime? appointmentDate;
  final String? appointmentTime;
  
  // Status
  final String status; // String to match backend values
  final List<StatusHistoryEntry>? statusHistory;
  final String? referralNotes;
  final String? responseNotes;
  final String? completionNotes;
  
  // Populated data for UI display
  final String? referringDoctorName;
  final String? referringDoctorLastName;
  final String? referringDoctorSpecialty;
  final String? referringDoctorProfilePicture;
  
  final String? targetDoctorName;
  final String? targetDoctorLastName;
  final String? targetDoctorSpecialty;
  final String? targetDoctorProfilePicture;
  
  final String? patientName;
  final String? patientLastName;
  final String? patientProfilePicture;
  final String? patientPhone;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReferralEntity({
    this.id,
    required this.referringDoctorId,
    required this.targetDoctorId,
    required this.patientId,
    this.referralDate,
    required this.reason,
    this.urgency = 'routine',
    this.specialty,
    this.diagnosis,
    this.symptoms,
    this.relevantHistory,
    this.currentMedications,
    this.specificConcerns,
    this.attachedDocuments,
    this.includeFullHistory = true,
    this.appointmentId,
    this.isAppointmentBooked = false,
    this.preferredDates,
    this.appointmentDate,
    this.appointmentTime,
    this.status = 'pending',
    this.statusHistory,
    this.referralNotes,
    this.responseNotes,
    this.completionNotes,
    this.referringDoctorName,
    this.referringDoctorLastName,
    this.referringDoctorSpecialty,
    this.referringDoctorProfilePicture,
    this.targetDoctorName,
    this.targetDoctorLastName,
    this.targetDoctorSpecialty,
    this.targetDoctorProfilePicture,
    this.patientName,
    this.patientLastName,
    this.patientProfilePicture,
    this.patientPhone,
    this.createdAt,
    this.updatedAt,
  });

  /// Get full name of referring doctor
  String get referringDoctorFullName =>
      '${referringDoctorName ?? ''} ${referringDoctorLastName ?? ''}'.trim();

  /// Get full name of target doctor
  String get targetDoctorFullName =>
      '${targetDoctorName ?? ''} ${targetDoctorLastName ?? ''}'.trim();

  /// Get full name of patient
  String get patientFullName =>
      '${patientName ?? ''} ${patientLastName ?? ''}'.trim();

  /// Get urgency display text
  String get urgencyDisplayText {
    switch (urgency.toLowerCase()) {
      case 'routine':
        return 'Routine';
      case 'urgent':
        return 'Urgent';
      case 'emergency':
        return 'Urgence';
      default:
        return urgency;
    }
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'scheduled':
        return 'Planifié';
      case 'accepted':
        return 'Accepté';
      case 'inprogress':
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'rejected':
        return 'Refusé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        referringDoctorId,
        targetDoctorId,
        patientId,
        referralDate,
        reason,
        urgency,
        specialty,
        status,
      ];
}
