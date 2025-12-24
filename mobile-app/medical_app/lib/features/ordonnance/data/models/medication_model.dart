import '../../domain/entities/prescription_entity.dart';

class MedicationModel {
  final String medicationName;
  final String dosage;
  final MedicationForm? form;
  final String frequency;
  final String duration;
  final String? instructions;
  final int? quantity;
  final String? notes;

  MedicationModel({
    required this.medicationName,
    required this.dosage,
    this.form,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.quantity,
    this.notes,
  });

  factory MedicationModel.fromEntity(MedicationEntity entity) {
    return MedicationModel(
      medicationName: entity.medicationName,
      dosage: entity.dosage,
      form: entity.form,
      frequency: entity.frequency,
      duration: entity.duration,
      instructions: entity.instructions,
      quantity: entity.quantity,
      notes: entity.notes,
    );
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
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

  MedicationEntity toEntity() {
    return MedicationEntity(
      medicationName: medicationName,
      dosage: dosage,
      form: form,
      frequency: frequency,
      duration: duration,
      instructions: instructions,
      quantity: quantity,
      notes: notes,
    );
  }
}
