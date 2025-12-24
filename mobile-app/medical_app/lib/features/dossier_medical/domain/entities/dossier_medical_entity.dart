import 'package:equatable/equatable.dart';
import 'medical_file_entity.dart';

class DossierMedicalEntity extends Equatable {
  final String id;
  final String patientId;
  final List<MedicalFileEntity> files;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DossierMedicalEntity({
    required this.id,
    required this.patientId,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty => files.isEmpty;
  bool get isNotEmpty => files.isNotEmpty;

  @override
  List<Object?> get props => [id, patientId, files, createdAt, updatedAt];
}
