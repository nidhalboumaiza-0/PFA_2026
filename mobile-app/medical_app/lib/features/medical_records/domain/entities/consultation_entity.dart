import 'package:equatable/equatable.dart';

/// Entity representing vital signs measured during a consultation
class VitalSignsEntity extends Equatable {
  final double? temperature;
  final String? bloodPressure;
  final int? heartRate;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final double? weight;
  final double? height;

  const VitalSignsEntity({
    this.temperature,
    this.bloodPressure,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
  });

  /// Calculate BMI if weight and height are available
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  @override
  List<Object?> get props => [
        temperature,
        bloodPressure,
        heartRate,
        respiratoryRate,
        oxygenSaturation,
        weight,
        height,
      ];
}

/// Entity representing medical notes from a consultation
class MedicalNoteEntity extends Equatable {
  final List<String>? symptoms;
  final String? diagnosis;
  final String? physicalExamination;
  final VitalSignsEntity? vitalSigns;
  final String? labResults;
  final String? additionalNotes;

  const MedicalNoteEntity({
    this.symptoms,
    this.diagnosis,
    this.physicalExamination,
    this.vitalSigns,
    this.labResults,
    this.additionalNotes,
  });

  @override
  List<Object?> get props => [
        symptoms,
        diagnosis,
        physicalExamination,
        vitalSigns,
        labResults,
        additionalNotes,
      ];
}

/// Entity representing a medical consultation
class ConsultationEntity extends Equatable {
  final String? id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime consultationDate;
  final String consultationType; // 'in-person', 'follow-up', 'referral'
  final String chiefComplaint;
  final MedicalNoteEntity medicalNote;
  final String? prescriptionId;
  final List<String>? documentIds;
  final bool requiresFollowUp;
  final DateTime? followUpDate;
  final String? followUpNotes;
  final bool isFromReferral;
  final String? referralId;
  final String status; // 'draft', 'completed', 'archived'
  final String? createdBy;
  final String? lastModifiedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated data for display
  final String? patientName;
  final String? doctorName;
  final String? doctorSpecialty;

  const ConsultationEntity({
    this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.consultationDate,
    this.consultationType = 'in-person',
    required this.chiefComplaint,
    required this.medicalNote,
    this.prescriptionId,
    this.documentIds,
    this.requiresFollowUp = false,
    this.followUpDate,
    this.followUpNotes,
    this.isFromReferral = false,
    this.referralId,
    this.status = 'completed',
    this.createdBy,
    this.lastModifiedBy,
    this.createdAt,
    this.updatedAt,
    this.patientName,
    this.doctorName,
    this.doctorSpecialty,
  });

  /// Check if consultation is editable
  bool get isEditable => status == 'draft';

  /// Get consultation type display name
  String get consultationTypeDisplay {
    switch (consultationType) {
      case 'in-person':
        return 'En personne';
      case 'follow-up':
        return 'Suivi';
      case 'referral':
        return 'Référence';
      default:
        return consultationType;
    }
  }

  /// Get status display name
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'completed':
        return 'Terminée';
      case 'archived':
        return 'Archivée';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        patientId,
        doctorId,
        consultationDate,
        consultationType,
        chiefComplaint,
        medicalNote,
        prescriptionId,
        documentIds,
        requiresFollowUp,
        followUpDate,
        followUpNotes,
        isFromReferral,
        referralId,
        status,
        createdBy,
        lastModifiedBy,
        createdAt,
        updatedAt,
      ];
}

/// Entity representing a timeline event for patient medical history
class TimelineEventEntity extends Equatable {
  final String id;
  final String consultationId;
  final String type; // 'consultation', 'follow-up', 'referral'
  final DateTime date;
  final String title;
  final String? description;
  final String? doctorId;
  final String? doctorName;
  final String? specialty;
  final String? diagnosis;
  final Map<String, dynamic>? data;

  const TimelineEventEntity({
    required this.id,
    required this.consultationId,
    required this.type,
    required this.date,
    required this.title,
    this.description,
    this.doctorId,
    this.doctorName,
    this.specialty,
    this.diagnosis,
    this.data,
  });

  @override
  List<Object?> get props => [
        id,
        consultationId,
        type,
        date,
        title,
        description,
        doctorId,
        doctorName,
        specialty,
        diagnosis,
        data,
      ];
}

/// Entity representing consultation statistics
class ConsultationStatisticsEntity extends Equatable {
  final int totalConsultations;
  final int completedConsultations;
  final int draftConsultations;
  final int cancelledConsultations;
  final int consultationsThisMonth;
  final int consultationsThisWeek;
  final Map<String, int>? consultationsByType;

  const ConsultationStatisticsEntity({
    required this.totalConsultations,
    required this.completedConsultations,
    required this.draftConsultations,
    required this.cancelledConsultations,
    required this.consultationsThisMonth,
    required this.consultationsThisWeek,
    this.consultationsByType,
  });

  @override
  List<Object?> get props => [
        totalConsultations,
        completedConsultations,
        draftConsultations,
        cancelledConsultations,
        consultationsThisMonth,
        consultationsThisWeek,
        consultationsByType,
      ];
}
