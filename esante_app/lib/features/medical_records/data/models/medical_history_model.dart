import '../../domain/entities/medical_history_entity.dart';

/// Data model for Medical History from API
class MedicalHistoryModel extends MedicalHistoryEntity {
  const MedicalHistoryModel({
    required super.patientId,
    required super.accessedBy,
    required super.accessedAt,
    required super.documents,
    required super.consultations,
    required super.prescriptions,
    required super.summary,
  });

  factory MedicalHistoryModel.fromJson(Map<String, dynamic> json) {
    final medicalHistory = json['medicalHistory'] as Map<String, dynamic>? ?? {};
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};

    return MedicalHistoryModel(
      patientId: json['patientId']?.toString() ?? '',
      accessedBy: json['accessedBy']?.toString() ?? '',
      accessedAt: DateTime.tryParse(json['accessedAt'] ?? '') ?? DateTime.now(),
      documents: (medicalHistory['documents'] as List<dynamic>?)
              ?.map((d) => MedicalDocumentModel.fromJson(d))
              .toList() ??
          [],
      consultations: (medicalHistory['consultations'] as List<dynamic>?)
              ?.map((c) => ConsultationSummaryModel.fromJson(c))
              .toList() ??
          [],
      prescriptions: (medicalHistory['prescriptions'] as List<dynamic>?)
              ?.map((p) => PrescriptionSummaryModel.fromJson(p))
              .toList() ??
          [],
      summary: MedicalHistorySummaryModel.fromJson(summaryJson),
    );
  }
}

/// Model for medical history summary
class MedicalHistorySummaryModel extends MedicalHistorySummaryEntity {
  const MedicalHistorySummaryModel({
    required super.totalDocuments,
    required super.totalConsultations,
    required super.totalPrescriptions,
    required super.diagnoses,
    required super.currentMedications,
  });

  factory MedicalHistorySummaryModel.fromJson(Map<String, dynamic> json) {
    return MedicalHistorySummaryModel(
      totalDocuments: json['totalDocuments'] ?? 0,
      totalConsultations: json['totalConsultations'] ?? 0,
      totalPrescriptions: json['totalPrescriptions'] ?? 0,
      diagnoses: (json['diagnoses'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      currentMedications: (json['currentMedications'] as List<dynamic>?)
              ?.map((m) => CurrentMedicationModel.fromJson(m))
              .toList() ??
          [],
    );
  }
}

/// Model for current medication
class CurrentMedicationModel extends CurrentMedicationEntity {
  const CurrentMedicationModel({
    required super.name,
    required super.dosage,
    required super.frequency,
  });

  factory CurrentMedicationModel.fromJson(Map<String, dynamic> json) {
    return CurrentMedicationModel(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }
}

/// Model for medical document
class MedicalDocumentModel extends MedicalDocumentEntity {
  const MedicalDocumentModel({
    required super.id,
    required super.title,
    super.description,
    required super.documentType,
    required super.fileName,
    required super.fileSize,
    required super.mimeType,
    super.downloadUrl,
    required super.uploadDate,
    required super.status,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    return MedicalDocumentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      documentType: json['documentType'] ?? 'other',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      downloadUrl: json['downloadUrl'],
      uploadDate: DateTime.tryParse(json['uploadDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}

/// Model for consultation summary
class ConsultationSummaryModel extends ConsultationSummaryEntity {
  const ConsultationSummaryModel({
    required super.id,
    required super.appointmentId,
    required super.doctorId,
    required super.consultationDate,
    required super.consultationType,
    super.chiefComplaint,
    super.diagnosis,
    super.symptoms,
    super.vitalSigns,
    super.followUpRequired,
    super.followUpDate,
  });

  factory ConsultationSummaryModel.fromJson(Map<String, dynamic> json) {
    final medicalNote = json['medicalNote'] as Map<String, dynamic>? ?? {};

    return ConsultationSummaryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      consultationDate:
          DateTime.tryParse(json['consultationDate'] ?? '') ?? DateTime.now(),
      consultationType: json['consultationType'] ?? 'in-person',
      chiefComplaint: json['chiefComplaint'],
      diagnosis: medicalNote['diagnosis'],
      symptoms: (medicalNote['symptoms'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      vitalSigns: medicalNote['vitalSigns'] != null
          ? VitalSignsModel.fromJson(medicalNote['vitalSigns'])
          : null,
      followUpRequired: json['followUpRequired'] ?? false,
      followUpDate: json['followUpDate'] != null
          ? DateTime.tryParse(json['followUpDate'])
          : null,
    );
  }
}

/// Model for vital signs
class VitalSignsModel extends VitalSignsEntity {
  const VitalSignsModel({
    super.bloodPressure,
    super.heartRate,
    super.temperature,
    super.weight,
    super.height,
    super.oxygenSaturation,
  });

  factory VitalSignsModel.fromJson(Map<String, dynamic> json) {
    return VitalSignsModel(
      bloodPressure: json['bloodPressure'],
      heartRate: json['heartRate'],
      temperature: (json['temperature'] as num?)?.toDouble(),
      weight: json['weight'],
      height: json['height'],
      oxygenSaturation: json['oxygenSaturation'],
    );
  }
}

/// Model for prescription summary
class PrescriptionSummaryModel extends PrescriptionSummaryEntity {
  const PrescriptionSummaryModel({
    required super.id,
    required super.doctorId,
    required super.prescriptionDate,
    required super.medications,
    required super.status,
  });

  factory PrescriptionSummaryModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionSummaryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      prescriptionDate:
          DateTime.tryParse(json['prescriptionDate'] ?? '') ?? DateTime.now(),
      medications: (json['medications'] as List<dynamic>?)
              ?.map((m) => MedicationModel.fromJson(m))
              .toList() ??
          [],
      status: json['status'] ?? 'active',
    );
  }
}

/// Model for medication
class MedicationModel extends MedicationEntity {
  const MedicationModel({
    required super.medicationName,
    required super.dosage,
    required super.frequency,
    super.durationDays,
    super.instructions,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      durationDays: json['durationDays'],
      instructions: json['instructions'],
    );
  }
}
