import 'package:equatable/equatable.dart';

/// Medication form types matching backend enum
enum MedicationForm {
  tablet,
  capsule,
  syrup,
  injection,
  cream,
  drops,
  inhaler,
  patch,
  other;

  static MedicationForm fromString(String? value) {
    return MedicationForm.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationForm.other,
    );
  }
}

class MedicationEntity extends Equatable {
  final String medicationName;
  final String dosage;
  final MedicationForm? form;
  final String frequency;
  final String duration;
  final String? instructions;
  final int? quantity;
  final String? notes;

  const MedicationEntity({
    required this.medicationName,
    required this.dosage,
    this.form,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.quantity,
    this.notes,
  });

  @override
  List<Object?> get props => [
    medicationName,
    dosage,
    form,
    frequency,
    duration,
    instructions,
    quantity,
    notes,
  ];

  factory MedicationEntity.fromJson(Map<String, dynamic> json) {
    return MedicationEntity(
      medicationName: json['medicationName'] as String? ?? json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      form: json['form'] != null ? MedicationForm.fromString(json['form'] as String?) : null,
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      instructions: json['instructions'] as String?,
      quantity: json['quantity'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'dosage': dosage,
      if (form != null) 'form': form!.name,
      'frequency': frequency,
      'duration': duration,
      if (instructions != null) 'instructions': instructions,
      if (quantity != null) 'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Modification history entry for prescription audit trail
class ModificationHistoryEntry extends Equatable {
  final DateTime modifiedAt;
  final String? modifiedBy;
  final String changeType;
  final Map<String, dynamic>? changes;
  final Map<String, dynamic>? previousData;

  const ModificationHistoryEntry({
    required this.modifiedAt,
    this.modifiedBy,
    required this.changeType,
    this.changes,
    this.previousData,
  });

  @override
  List<Object?> get props => [modifiedAt, modifiedBy, changeType, changes, previousData];

  factory ModificationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ModificationHistoryEntry(
      modifiedAt: DateTime.tryParse(json['modifiedAt'] ?? '') ?? DateTime.now(),
      modifiedBy: json['modifiedBy'] as String?,
      changeType: json['changeType'] as String? ?? 'updated',
      changes: json['changes'] as Map<String, dynamic>?,
      previousData: json['previousData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modifiedAt': modifiedAt.toIso8601String(),
      if (modifiedBy != null) 'modifiedBy': modifiedBy,
      'changeType': changeType,
      if (changes != null) 'changes': changes,
      if (previousData != null) 'previousData': previousData,
    };
  }
}

class PrescriptionEntity extends Equatable {
  final String id;
  final String consultationId;
  final String patientId;
  final String? patientName; // Populated from patient ref
  final String doctorId;
  final String? doctorName; // Populated from doctor ref
  final DateTime prescriptionDate;
  final List<MedicationEntity> medications;
  final String? generalInstructions;
  final String? specialWarnings;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? canEditUntil;
  final List<ModificationHistoryEntry> modificationHistory;
  final String status;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrescriptionEntity({
    required this.id,
    required this.consultationId,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    required this.prescriptionDate,
    required this.medications,
    this.generalInstructions,
    this.specialWarnings,
    this.isLocked = false,
    this.lockedAt,
    this.canEditUntil,
    this.modificationHistory = const [],
    this.status = 'active',
    this.pharmacyName,
    this.pharmacyAddress,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if prescription can still be edited
  bool get canEdit {
    if (isLocked) return false;
    if (canEditUntil == null) return true;
    return DateTime.now().isBefore(canEditUntil!);
  }

  @override
  List<Object?> get props => [
    id,
    consultationId,
    patientId,
    patientName,
    doctorId,
    doctorName,
    prescriptionDate,
    medications,
    generalInstructions,
    specialWarnings,
    isLocked,
    lockedAt,
    canEditUntil,
    modificationHistory,
    status,
    pharmacyName,
    pharmacyAddress,
    createdBy,
    createdAt,
    updatedAt,
  ];

  // Factory method to create a new prescription
  factory PrescriptionEntity.create({
    required String id,
    required String consultationId,
    required String patientId,
    String? patientName,
    required String doctorId,
    String? doctorName,
    required List<MedicationEntity> medications,
    String? generalInstructions,
    String? specialWarnings,
    String? pharmacyName,
    String? pharmacyAddress,
    required String createdBy,
    String status = 'active',
  }) {
    final now = DateTime.now();
    return PrescriptionEntity(
      id: id,
      consultationId: consultationId,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      prescriptionDate: now,
      medications: medications,
      generalInstructions: generalInstructions,
      specialWarnings: specialWarnings,
      isLocked: false,
      canEditUntil: now.add(const Duration(hours: 24)), // 24h edit window
      modificationHistory: [
        ModificationHistoryEntry(
          modifiedAt: now,
          modifiedBy: createdBy,
          changeType: 'created',
        ),
      ],
      status: status,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }
}
