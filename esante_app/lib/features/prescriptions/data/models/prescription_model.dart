import 'package:equatable/equatable.dart';

/// Represents the appointment/consultation context for a prescription
class AppointmentInfoModel extends Equatable {
  final DateTime? consultationDate;
  final String? consultationType;
  final String? chiefComplaint;
  final String? diagnosis;

  const AppointmentInfoModel({
    this.consultationDate,
    this.consultationType,
    this.chiefComplaint,
    this.diagnosis,
  });

  factory AppointmentInfoModel.fromJson(Map<String, dynamic> json) {
    return AppointmentInfoModel(
      consultationDate: json['consultationDate'] != null
          ? DateTime.parse(json['consultationDate'])
          : null,
      consultationType: json['consultationType'],
      chiefComplaint: json['chiefComplaint'],
      diagnosis: json['diagnosis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationDate': consultationDate?.toIso8601String(),
      'consultationType': consultationType,
      'chiefComplaint': chiefComplaint,
      'diagnosis': diagnosis,
    };
  }

  @override
  List<Object?> get props => [
        consultationDate,
        consultationType,
        chiefComplaint,
        diagnosis,
      ];
}

/// Represents a single medication in a prescription
class MedicationModel extends Equatable {
  final String name;
  final String dosage;
  final String? form;
  final String frequency;
  final String duration;
  final String? instructions;

  const MedicationModel({
    required this.name,
    required this.dosage,
    this.form,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      name: json['name'] ?? json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      form: json['form'],
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'form': form,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  /// Returns a formatted string for display
  String get formattedDosage => '$dosage ${form ?? ''}'.trim();

  @override
  List<Object?> get props => [name, dosage, form, frequency, duration, instructions];
}

/// Represents doctor info in prescription response
class PrescriptionDoctorModel extends Equatable {
  final String name;
  final String? specialty;

  const PrescriptionDoctorModel({
    required this.name,
    this.specialty,
  });

  factory PrescriptionDoctorModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionDoctorModel(
      name: json['name'] ?? 'Unknown Doctor',
      specialty: json['specialty'],
    );
  }

  @override
  List<Object?> get props => [name, specialty];
}

/// Main prescription model
class PrescriptionModel extends Equatable {
  final String id;
  final DateTime date;
  final PrescriptionDoctorModel doctor;
  final AppointmentInfoModel? appointment;
  final List<MedicationModel> medications;
  final int medicationCount;
  final String? generalInstructions;
  final String? specialWarnings;
  final String? pharmacyName;
  final String status;
  final DateTime? createdAt;

  const PrescriptionModel({
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

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] ?? json['_id'] ?? '',
      date: DateTime.parse(json['date'] ?? json['prescriptionDate']),
      doctor: PrescriptionDoctorModel.fromJson(json['doctor'] ?? {}),
      appointment: json['appointment'] != null
          ? AppointmentInfoModel.fromJson(json['appointment'])
          : null,
      medications: (json['medications'] as List<dynamic>?)
              ?.map((m) => MedicationModel.fromJson(m))
              .toList() ??
          [],
      medicationCount: json['medicationCount'] ?? 0,
      generalInstructions: json['generalInstructions'],
      specialWarnings: json['specialWarnings'],
      pharmacyName: json['pharmacyName'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'doctor': {
        'name': doctor.name,
        'specialty': doctor.specialty,
      },
      'appointment': appointment?.toJson(),
      'medications': medications.map((m) => m.toJson()).toList(),
      'medicationCount': medicationCount,
      'generalInstructions': generalInstructions,
      'specialWarnings': specialWarnings,
      'pharmacyName': pharmacyName,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Check if prescription is active
  bool get isActive => status == 'active';

  /// Check if prescription has warnings
  bool get hasWarnings => specialWarnings != null && specialWarnings!.isNotEmpty;

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
