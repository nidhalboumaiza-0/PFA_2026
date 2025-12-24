import 'package:equatable/equatable.dart';

class OrdonnanceEntity extends Equatable {
  final String id;
  final String patientName;
  final String medication;
  final String dosage;
  final String instructions;
  final DateTime date;

  const OrdonnanceEntity({
    required this.id,
    required this.patientName,
    required this.medication,
    required this.dosage,
    required this.instructions,
    required this.date,
  });

  // Méthode statique pour créer une instance
  factory OrdonnanceEntity.create({
    required String id,
    required String patientName,
    required String medication,
    required String dosage,
    required String instructions,
    required DateTime date,
  }) {
    return OrdonnanceEntity(
      id: id,
      patientName: patientName,
      medication: medication,
      dosage: dosage,
      instructions: instructions,
      date: date,
    );
  }

  // Liste des propriétés pour l'égalité
  @override
  List<Object?> get props => [
    id,
    patientName,
    medication,
    dosage,
    instructions,
    date,
  ];
}