import 'package:equatable/equatable.dart';

/// Represents the appointment/consultation context for a prescription
class AppointmentInfoEntity extends Equatable {
  final DateTime? consultationDate;
  final String? consultationType;
  final String? chiefComplaint;
  final String? diagnosis;

  const AppointmentInfoEntity({
    this.consultationDate,
    this.consultationType,
    this.chiefComplaint,
    this.diagnosis,
  });

  @override
  List<Object?> get props => [
        consultationDate,
        consultationType,
        chiefComplaint,
        diagnosis,
      ];
}

/// Represents a single medication in a prescription
class MedicationEntity extends Equatable {
  final String name;
  final String dosage;
  final String? form;
  final String frequency;
  final String duration;
  final String? instructions;

  const MedicationEntity({
    required this.name,
    required this.dosage,
    this.form,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  /// Returns a formatted string for display
  String get formattedDosage => '$dosage ${form ?? ''}'.trim();

  @override
  List<Object?> get props => [name, dosage, form, frequency, duration, instructions];
}

/// Represents doctor info in prescription
class PrescriptionDoctorEntity extends Equatable {
  final String name;
  final String? specialty;

  const PrescriptionDoctorEntity({
    required this.name,
    this.specialty,
  });

  @override
  List<Object?> get props => [name, specialty];
}

/// Main prescription entity
class PrescriptionEntity extends Equatable {
  final String id;
  final DateTime date;
  final PrescriptionDoctorEntity doctor;
  final AppointmentInfoEntity? appointment;
  final List<MedicationEntity> medications;
  final int medicationCount;
  final String? generalInstructions;
  final String? specialWarnings;
  final String? pharmacyName;
  final String status;
  final DateTime? createdAt;

  const PrescriptionEntity({
    required this.id,
    required this.date,
    required this.doctor,
    this.appointment,
    required this.medications,
    required this.medicationCount,
    this.generalInstructions,
    this.specialWarnings,
    this.pharmacyName,
    required this.status,
    this.createdAt,
  });

  /// Check if prescription is active
  bool get isActive => status == 'active';

  /// Check if prescription has warnings
  bool get hasWarnings => specialWarnings != null && specialWarnings!.isNotEmpty;

  /// Check if prescription has appointment context
  bool get hasAppointmentInfo => appointment != null;

  @override
  List<Object?> get props => [
        id,
        date,
        doctor,
        appointment,
        medications,
        medicationCount,
        generalInstructions,
        specialWarnings,
        pharmacyName,
        status,
        createdAt,
      ];
}
