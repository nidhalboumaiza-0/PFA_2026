import '../../domain/entities/dossier_medical_entity.dart';
import 'medical_file_model.dart';

class DossierMedicalModel extends DossierMedicalEntity {
  const DossierMedicalModel({
    required String id,
    required String patientId,
    required List<MedicalFileModel> files,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         id: id,
         patientId: patientId,
         files: files,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory DossierMedicalModel.fromJson(Map<String, dynamic> json) {
    return DossierMedicalModel(
      id: json['_id'] ?? json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      files:
          json['files'] != null
              ? List<MedicalFileModel>.from(
                (json['files'] as List).map(
                  (file) => MedicalFileModel.fromJson(file),
                ),
              )
              : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'files':
          files.map((file) => (file as MedicalFileModel).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DossierMedicalModel.empty(String patientId) {
    return DossierMedicalModel(
      id: '',
      patientId: patientId,
      files: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
