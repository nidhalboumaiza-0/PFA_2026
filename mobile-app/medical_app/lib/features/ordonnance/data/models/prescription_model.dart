import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/prescription_entity.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required super.id,
    required super.consultationId,
    required super.patientId,
    super.patientName,
    required super.doctorId,
    super.doctorName,
    required super.prescriptionDate,
    required super.medications,
    super.generalInstructions,
    super.specialWarnings,
    super.isLocked = false,
    super.lockedAt,
    super.canEditUntil,
    super.modificationHistory = const [],
    super.status = 'active',
    super.pharmacyName,
    super.pharmacyAddress,
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  // Convert to JSON for API or storage
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'consultationId': consultationId,
      'patientId': patientId,
      'doctorId': doctorId,
      'prescriptionDate': prescriptionDate.toIso8601String(),
      'medications': medications.map((m) => m.toJson()).toList(),
      if (generalInstructions != null) 'generalInstructions': generalInstructions,
      if (specialWarnings != null) 'specialWarnings': specialWarnings,
      'isLocked': isLocked,
      if (lockedAt != null) 'lockedAt': lockedAt!.toIso8601String(),
      if (canEditUntil != null) 'canEditUntil': canEditUntil!.toIso8601String(),
      'modificationHistory': modificationHistory.map((m) => m.toJson()).toList(),
      'status': status,
      if (pharmacyName != null) 'pharmacyName': pharmacyName,
      if (pharmacyAddress != null) 'pharmacyAddress': pharmacyAddress,
      'createdBy': createdBy,
    };
  }

  // Create from JSON - handles both backend format and legacy format
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<MedicationEntity> meds = [];
    if (json['medications'] != null) {
      final medications = json['medications'] as List;
      meds = medications
          .map((m) => MedicationEntity.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    List<ModificationHistoryEntry> history = [];
    if (json['modificationHistory'] != null) {
      final historyList = json['modificationHistory'] as List;
      history = historyList
          .map((h) => ModificationHistoryEntry.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // Handle MongoDB _id vs id
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    
    // Handle consultationId - also support legacy 'appointment' field
    final consultationId = json['consultationId']?.toString() ?? 
        json['appointment']?.toString() ?? '';
    
    // Handle patientId - can be string or populated object
    String patientId;
    String? patientName;
    if (json['patientId'] is Map) {
      final patientMap = json['patientId'] as Map<String, dynamic>;
      patientId = patientMap['_id']?.toString() ?? '';
      patientName = '${patientMap['nom'] ?? ''} ${patientMap['prenom'] ?? ''}'.trim();
    } else {
      patientId = json['patientId']?.toString() ?? json['patient']?.toString() ?? '';
      patientName = json['patientName'] as String?;
    }

    // Handle doctorId - can be string or populated object
    String doctorId;
    String? doctorName;
    if (json['doctorId'] is Map) {
      final doctorMap = json['doctorId'] as Map<String, dynamic>;
      doctorId = doctorMap['_id']?.toString() ?? '';
      doctorName = '${doctorMap['nom'] ?? ''} ${doctorMap['prenom'] ?? ''}'.trim();
    } else {
      doctorId = json['doctorId']?.toString() ?? json['medecin']?.toString() ?? '';
      doctorName = json['doctorName'] as String?;
    }

    // Handle createdBy - can be string or populated object
    String createdBy;
    if (json['createdBy'] is Map) {
      createdBy = (json['createdBy'] as Map)['_id']?.toString() ?? '';
    } else {
      createdBy = json['createdBy']?.toString() ?? doctorId;
    }

    return PrescriptionModel(
      id: id,
      consultationId: consultationId,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      prescriptionDate: parseDate(json['prescriptionDate'] ?? json['date']),
      medications: meds,
      generalInstructions: json['generalInstructions'] as String? ?? json['note'] as String?,
      specialWarnings: json['specialWarnings'] as String?,
      isLocked: json['isLocked'] as bool? ?? false,
      lockedAt: parseDateNullable(json['lockedAt']),
      canEditUntil: parseDateNullable(json['canEditUntil']),
      modificationHistory: history,
      status: json['status'] as String? ?? 'active',
      pharmacyName: json['pharmacyName'] as String?,
      pharmacyAddress: json['pharmacyAddress'] as String?,
      createdBy: createdBy,
      createdAt: parseDateNullable(json['createdAt']),
      updatedAt: parseDateNullable(json['updatedAt']),
    );
  }

  // Create from entity
  factory PrescriptionModel.fromEntity(PrescriptionEntity entity) {
    return PrescriptionModel(
      id: entity.id,
      consultationId: entity.consultationId,
      patientId: entity.patientId,
      patientName: entity.patientName,
      doctorId: entity.doctorId,
      doctorName: entity.doctorName,
      prescriptionDate: entity.prescriptionDate,
      medications: entity.medications,
      generalInstructions: entity.generalInstructions,
      specialWarnings: entity.specialWarnings,
      isLocked: entity.isLocked,
      lockedAt: entity.lockedAt,
      canEditUntil: entity.canEditUntil,
      modificationHistory: entity.modificationHistory,
      status: entity.status,
      pharmacyName: entity.pharmacyName,
      pharmacyAddress: entity.pharmacyAddress,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
