import 'package:equatable/equatable.dart';

class RendezVousEntity extends Equatable {
  final String? id; // MongoDB _id
  final DateTime startDate; // Start date of appointment
  final DateTime endDate; // End date of appointment
  final String serviceName; // Name of the service
  final String patient; // MongoDB ObjectId reference
  final String medecin; // MongoDB ObjectId reference
  final String
  status; // Status: "En attente", "Accepté", "Refusé", "Annulé", "Terminé"
  final String? motif; // Reason for appointment
  final String? notes; // Additional notes
  final List<String>? symptoms; // List of symptoms
  final bool isRated; // Whether the appointment has been rated
  final bool hasPrescription; // Whether the appointment has a prescription
  final DateTime? createdAt; // Creation date

  // Reschedule-related fields
  final bool isRescheduled; // Whether the appointment has been rescheduled
  final String? rescheduledBy; // Who rescheduled (doctor/patient)
  final DateTime? previousDate; // Previous date before reschedule
  final RescheduleRequest? rescheduleRequest; // Pending reschedule request

  // Additional fields for UI display purposes
  final String? patientName; // UI display - not in MongoDB schema
  final String? patientLastName; // UI display - not in MongoDB schema
  final String? patientProfilePicture; // UI display - not in MongoDB schema
  final String? patientPhoneNumber; // UI display - not in MongoDB schema
  final String? medecinName; // UI display - not in MongoDB schema
  final String? medecinLastName; // UI display - not in MongoDB schema
  final String? medecinProfilePicture; // UI display - not in MongoDB schema
  final String? medecinSpeciality; // UI display - not in MongoDB schema

  const RendezVousEntity({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.serviceName,
    required this.patient,
    required this.medecin,
    required this.status,
    this.motif,
    this.notes,
    this.symptoms,
    this.isRated = false,
    this.hasPrescription = false,
    this.createdAt,
    // Reschedule fields
    this.isRescheduled = false,
    this.rescheduledBy,
    this.previousDate,
    this.rescheduleRequest,
    // UI display fields
    this.patientName,
    this.patientLastName,
    this.patientProfilePicture,
    this.patientPhoneNumber,
    this.medecinName,
    this.medecinLastName,
    this.medecinProfilePicture,
    this.medecinSpeciality,
  });

  /// Check if there's a pending reschedule request
  bool get hasPendingRescheduleRequest =>
      rescheduleRequest != null && rescheduleRequest!.status == 'pending';

  factory RendezVousEntity.create({
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
  }) {
    return RendezVousEntity(
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
  }

  @override
  List<Object?> get props => [
    id,
    startDate,
    endDate,
    serviceName,
    patient,
    medecin,
    status,
    motif,
    notes,
    symptoms,
    isRated,
    hasPrescription,
    createdAt,
    isRescheduled,
    rescheduledBy,
    previousDate,
    rescheduleRequest,
    patientName,
    patientLastName,
    patientProfilePicture,
    patientPhoneNumber,
    medecinName,
    medecinLastName,
    medecinProfilePicture,
    medecinSpeciality,
  ];
}

/// Represents a pending reschedule request from patient
class RescheduleRequest extends Equatable {
  final DateTime requestedDate;
  final String requestedTime;
  final String? reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  const RescheduleRequest({
    required this.requestedDate,
    required this.requestedTime,
    this.reason,
    required this.status,
    required this.requestedAt,
  });

  factory RescheduleRequest.fromJson(Map<String, dynamic> json) {
    return RescheduleRequest(
      requestedDate: DateTime.parse(json['requestedDate']),
      requestedTime: json['requestedTime'] ?? '',
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestedDate': requestedDate.toIso8601String(),
      'requestedTime': requestedTime,
      'reason': reason,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    requestedDate,
    requestedTime,
    reason,
    status,
    requestedAt,
  ];
}
