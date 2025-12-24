import '../../domain/entities/ordonnance_entity.dart';

class OrdonnanceModel {
  final String id;
  final String patientName;
  final String medication;
  final String dosage;
  final String instructions;
  final DateTime date;

  OrdonnanceModel({
    required this.id,
    required this.patientName,
    required this.medication,
    required this.dosage,
    required this.instructions,
    required this.date,
  });

  // Conversion en JSON pour API ou stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'medication': medication,
      'dosage': dosage,
      'instructions': instructions,
      'date': date.toIso8601String(),
    };
  }

  // Création à partir de JSON
  factory OrdonnanceModel.fromJson(Map<String, dynamic> json) {
    return OrdonnanceModel(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      medication: json['medication'] as String,
      dosage: json['dosage'] as String,
      instructions: json['instructions'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Conversion vers l'entité
  OrdonnanceEntity toEntity() {
    return OrdonnanceEntity(
      id: id,
      patientName: patientName,
      medication: medication,
      dosage: dosage,
      instructions: instructions,
      date: date,
    );
  }
}
