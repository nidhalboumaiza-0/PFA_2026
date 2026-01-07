import 'package:equatable/equatable.dart';

/// Represents a patient's complete medical history
class MedicalHistoryEntity extends Equatable {
  final String patientId;
  final String accessedBy;
  final DateTime accessedAt;
  final List<MedicalDocumentEntity> documents;
  final List<ConsultationSummaryEntity> consultations;
  final List<PrescriptionSummaryEntity> prescriptions;
  final MedicalHistorySummaryEntity summary;

  const MedicalHistoryEntity({
    required this.patientId,
    required this.accessedBy,
    required this.accessedAt,
    required this.documents,
    required this.consultations,
    required this.prescriptions,
    required this.summary,
  });

  @override
  List<Object?> get props => [
        patientId,
        accessedBy,
        accessedAt,
        documents,
        consultations,
        prescriptions,
        summary,
      ];
}

/// Summary statistics for the medical history
class MedicalHistorySummaryEntity extends Equatable {
  final int totalDocuments;
  final int totalConsultations;
  final int totalPrescriptions;
  final List<String> diagnoses;
  final List<CurrentMedicationEntity> currentMedications;

  const MedicalHistorySummaryEntity({
    required this.totalDocuments,
    required this.totalConsultations,
    required this.totalPrescriptions,
    required this.diagnoses,
    required this.currentMedications,
  });

  @override
  List<Object?> get props => [
        totalDocuments,
        totalConsultations,
        totalPrescriptions,
        diagnoses,
        currentMedications,
      ];
}

/// Current active medication
class CurrentMedicationEntity extends Equatable {
  final String name;
  final String dosage;
  final String frequency;

  const CurrentMedicationEntity({
    required this.name,
    required this.dosage,
    required this.frequency,
  });

  @override
  List<Object?> get props => [name, dosage, frequency];
}

/// Document in patient's medical history
class MedicalDocumentEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String documentType;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? downloadUrl;
  final DateTime uploadDate;
  final String status;

  const MedicalDocumentEntity({
    required this.id,
    required this.title,
    this.description,
    required this.documentType,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.downloadUrl,
    required this.uploadDate,
    required this.status,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        documentType,
        fileName,
        fileSize,
        mimeType,
        downloadUrl,
        uploadDate,
        status,
      ];
}

/// Consultation summary in medical history
class ConsultationSummaryEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String doctorId;
  final DateTime consultationDate;
  final String consultationType;
  final String? chiefComplaint;
  final String? diagnosis;
  final List<String> symptoms;
  final VitalSignsEntity? vitalSigns;
  final bool followUpRequired;
  final DateTime? followUpDate;

  const ConsultationSummaryEntity({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.consultationDate,
    required this.consultationType,
    this.chiefComplaint,
    this.diagnosis,
    this.symptoms = const [],
    this.vitalSigns,
    this.followUpRequired = false,
    this.followUpDate,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        doctorId,
        consultationDate,
        consultationType,
        chiefComplaint,
        diagnosis,
        symptoms,
        vitalSigns,
        followUpRequired,
        followUpDate,
      ];
}

/// Vital signs recorded during consultation
class VitalSignsEntity extends Equatable {
  final String? bloodPressure;
  final int? heartRate;
  final double? temperature;
  final int? weight;
  final int? height;
  final int? oxygenSaturation;

  const VitalSignsEntity({
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    this.oxygenSaturation,
  });

  @override
  List<Object?> get props => [
        bloodPressure,
        heartRate,
        temperature,
        weight,
        height,
        oxygenSaturation,
      ];
}

/// Prescription summary in medical history
class PrescriptionSummaryEntity extends Equatable {
  final String id;
  final String doctorId;
  final DateTime prescriptionDate;
  final List<MedicationEntity> medications;
  final String status;

  const PrescriptionSummaryEntity({
    required this.id,
    required this.doctorId,
    required this.prescriptionDate,
    required this.medications,
    required this.status,
  });

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id, doctorId, prescriptionDate, medications, status];
}

/// Individual medication in a prescription
class MedicationEntity extends Equatable {
  final String medicationName;
  final String dosage;
  final String frequency;
  final int? durationDays;
  final String? instructions;

  const MedicationEntity({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    this.durationDays,
    this.instructions,
  });

  @override
  List<Object?> get props => [
        medicationName,
        dosage,
        frequency,
        durationDays,
        instructions,
      ];
}
