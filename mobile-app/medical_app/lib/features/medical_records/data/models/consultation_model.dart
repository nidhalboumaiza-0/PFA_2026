import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';

/// Model for vital signs with JSON serialization
class VitalSignsModel extends VitalSignsEntity {
  const VitalSignsModel({
    super.temperature,
    super.bloodPressure,
    super.heartRate,
    super.respiratoryRate,
    super.oxygenSaturation,
    super.weight,
    super.height,
  });

  factory VitalSignsModel.fromJson(Map<String, dynamic> json) {
    return VitalSignsModel(
      temperature: json['temperature']?.toDouble(),
      bloodPressure: json['bloodPressure'],
      heartRate: json['heartRate']?.toInt(),
      respiratoryRate: json['respiratoryRate']?.toInt(),
      oxygenSaturation: json['oxygenSaturation']?.toInt(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (bloodPressure != null) 'bloodPressure': bloodPressure,
      if (heartRate != null) 'heartRate': heartRate,
      if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
      if (oxygenSaturation != null) 'oxygenSaturation': oxygenSaturation,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
    };
  }
}

/// Model for medical notes with JSON serialization
class MedicalNoteModel extends MedicalNoteEntity {
  const MedicalNoteModel({
    super.symptoms,
    super.diagnosis,
    super.physicalExamination,
    super.vitalSigns,
    super.labResults,
    super.additionalNotes,
  });

  factory MedicalNoteModel.fromJson(Map<String, dynamic> json) {
    return MedicalNoteModel(
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : null,
      diagnosis: json['diagnosis'],
      physicalExamination: json['physicalExamination'],
      vitalSigns: json['vitalSigns'] != null
          ? VitalSignsModel.fromJson(json['vitalSigns'])
          : null,
      labResults: json['labResults'],
      additionalNotes: json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (symptoms != null) 'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (physicalExamination != null)
        'physicalExamination': physicalExamination,
      if (vitalSigns != null)
        'vitalSigns': (vitalSigns as VitalSignsModel?)?.toJson() ??
            VitalSignsModel(
              temperature: vitalSigns?.temperature,
              bloodPressure: vitalSigns?.bloodPressure,
              heartRate: vitalSigns?.heartRate,
              respiratoryRate: vitalSigns?.respiratoryRate,
              oxygenSaturation: vitalSigns?.oxygenSaturation,
              weight: vitalSigns?.weight,
              height: vitalSigns?.height,
            ).toJson(),
      if (labResults != null) 'labResults': labResults,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    };
  }
}

/// Model for consultation with JSON serialization
class ConsultationModel extends ConsultationEntity {
  const ConsultationModel({
    super.id,
    required super.appointmentId,
    required super.patientId,
    required super.doctorId,
    required super.consultationDate,
    super.consultationType,
    required super.chiefComplaint,
    required super.medicalNote,
    super.prescriptionId,
    super.documentIds,
    super.requiresFollowUp,
    super.followUpDate,
    super.followUpNotes,
    super.isFromReferral,
    super.referralId,
    super.status,
    super.createdBy,
    super.lastModifiedBy,
    super.createdAt,
    super.updatedAt,
    super.patientName,
    super.doctorName,
    super.doctorSpecialty,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    // Extract patient info
    String patientId = '';
    String? patientName;
    if (json['patientId'] is String) {
      patientId = json['patientId'];
    } else if (json['patientId'] is Map) {
      patientId = json['patientId']['_id'] ?? '';
      patientName =
          '${json['patientId']['nom'] ?? ''} ${json['patientId']['prenom'] ?? ''}'
              .trim();
    }

    // Extract doctor info
    String doctorId = '';
    String? doctorName;
    String? doctorSpecialty;
    if (json['doctorId'] is String) {
      doctorId = json['doctorId'];
    } else if (json['doctorId'] is Map) {
      doctorId = json['doctorId']['_id'] ?? '';
      doctorName =
          '${json['doctorId']['nom'] ?? ''} ${json['doctorId']['prenom'] ?? ''}'
              .trim();
      doctorSpecialty = json['doctorId']['specialite'];
    }

    // Parse document IDs
    List<String>? documentIds;
    if (json['documentIds'] != null) {
      documentIds = (json['documentIds'] as List).map((doc) {
        if (doc is String) return doc;
        if (doc is Map) return doc['_id']?.toString() ?? '';
        return '';
      }).where((id) => id.isNotEmpty).toList();
    }

    return ConsultationModel(
      id: json['_id'] ?? json['id'],
      appointmentId: json['appointmentId'] is String
          ? json['appointmentId']
          : json['appointmentId']?['_id'] ?? '',
      patientId: patientId,
      doctorId: doctorId,
      consultationDate:
          DateTime.tryParse(json['consultationDate'] ?? '') ?? DateTime.now(),
      consultationType: json['consultationType'] ?? 'in-person',
      chiefComplaint: json['chiefComplaint'] ?? '',
      medicalNote: json['medicalNote'] != null
          ? MedicalNoteModel.fromJson(json['medicalNote'])
          : const MedicalNoteModel(),
      prescriptionId: json['prescriptionId'] is String
          ? json['prescriptionId']
          : json['prescriptionId']?['_id'],
      documentIds: documentIds,
      requiresFollowUp: json['requiresFollowUp'] ?? false,
      followUpDate: DateTime.tryParse(json['followUpDate'] ?? ''),
      followUpNotes: json['followUpNotes'],
      isFromReferral: json['isFromReferral'] ?? false,
      referralId: json['referralId'] is String
          ? json['referralId']
          : json['referralId']?['_id'],
      status: json['status'] ?? 'completed',
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'],
      lastModifiedBy: json['lastModifiedBy'] is String
          ? json['lastModifiedBy']
          : json['lastModifiedBy']?['_id'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      patientName: patientName,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'consultationDate': consultationDate.toIso8601String(),
      'consultationType': consultationType,
      'chiefComplaint': chiefComplaint,
      'medicalNote': (medicalNote as MedicalNoteModel?)?.toJson() ??
          MedicalNoteModel(
            symptoms: medicalNote.symptoms,
            diagnosis: medicalNote.diagnosis,
            physicalExamination: medicalNote.physicalExamination,
            labResults: medicalNote.labResults,
            additionalNotes: medicalNote.additionalNotes,
          ).toJson(),
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
      if (documentIds != null) 'documentIds': documentIds,
      'requiresFollowUp': requiresFollowUp,
      if (followUpDate != null) 'followUpDate': followUpDate!.toIso8601String(),
      if (followUpNotes != null) 'followUpNotes': followUpNotes,
      'isFromReferral': isFromReferral,
      if (referralId != null) 'referralId': referralId,
      'status': status,
    };
  }

  /// Create request body for creating a new consultation
  static Map<String, dynamic> createRequest({
    required String appointmentId,
    required String chiefComplaint,
    required MedicalNoteModel medicalNote,
    String consultationType = 'in-person',
    bool requiresFollowUp = false,
    DateTime? followUpDate,
    String? followUpNotes,
    String? referralId,
  }) {
    return {
      'appointmentId': appointmentId,
      'chiefComplaint': chiefComplaint,
      'medicalNote': medicalNote.toJson(),
      'consultationType': consultationType,
      'requiresFollowUp': requiresFollowUp,
      if (followUpDate != null) 'followUpDate': followUpDate.toIso8601String(),
      if (followUpNotes != null) 'followUpNotes': followUpNotes,
      if (referralId != null) 'referralId': referralId,
    };
  }
}

/// Model for timeline event
class TimelineEventModel extends TimelineEventEntity {
  const TimelineEventModel({
    required super.id,
    required super.consultationId,
    required super.type,
    required super.date,
    required super.title,
    super.description,
    super.doctorId,
    super.doctorName,
    super.specialty,
    super.diagnosis,
    super.data,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    // Handle doctor info if populated
    String? doctorId;
    String? doctorName;
    String? specialty;
    
    if (json['doctor'] is Map) {
      final doctorData = json['doctor'] as Map<String, dynamic>;
      doctorId = doctorData['_id']?.toString();
      doctorName = '${doctorData['nom'] ?? ''} ${doctorData['prenom'] ?? ''}'.trim();
      specialty = doctorData['specialty'] as String?;
    } else {
      doctorId = json['doctorId']?.toString();
      doctorName = json['doctorName'] as String?;
    }
    
    return TimelineEventModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      consultationId: json['consultationId']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type'] as String? ?? 'consultation',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      title: json['title'] as String? ?? json['chiefComplaint'] as String? ?? '',
      description: json['description'] as String?,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      diagnosis: json['diagnosis'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Model for consultation statistics
class ConsultationStatisticsModel extends ConsultationStatisticsEntity {
  const ConsultationStatisticsModel({
    required super.totalConsultations,
    required super.completedConsultations,
    required super.draftConsultations,
    required super.cancelledConsultations,
    required super.consultationsThisMonth,
    required super.consultationsThisWeek,
    super.consultationsByType,
  });

  factory ConsultationStatisticsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int>? byType;
    if (json['consultationsByType'] != null) {
      byType = Map<String, int>.from(
        (json['consultationsByType'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      );
    }

    return ConsultationStatisticsModel(
      totalConsultations: json['totalConsultations'] ?? 0,
      completedConsultations: json['completedConsultations'] ?? 0,
      draftConsultations: json['draftConsultations'] ?? 0,
      cancelledConsultations: json['cancelledConsultations'] ?? 0,
      consultationsThisMonth: json['consultationsThisMonth'] ?? 0,
      consultationsThisWeek: json['consultationsThisWeek'] ?? 0,
      consultationsByType: byType,
    );
  }
}
