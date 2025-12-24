import 'package:equatable/equatable.dart';

abstract class DossierMedicalEvent extends Equatable {
  const DossierMedicalEvent();

  @override
  List<Object?> get props => [];
}

class FetchDossierMedical extends DossierMedicalEvent {
  final String patientId;

  const FetchDossierMedical({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

class CheckDossierMedicalExists extends DossierMedicalEvent {
  final String patientId;

  const CheckDossierMedicalExists({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

class UploadSingleFile extends DossierMedicalEvent {
  final String patientId;
  final String filePath;
  final String description;

  const UploadSingleFile({
    required this.patientId,
    required this.filePath,
    this.description = '',
  });

  @override
  List<Object?> get props => [patientId, filePath, description];
}

class UploadMultipleFiles extends DossierMedicalEvent {
  final String patientId;
  final List<String> filePaths;
  final Map<String, String> descriptions;

  const UploadMultipleFiles({
    required this.patientId,
    required this.filePaths,
    this.descriptions = const {},
  });

  @override
  List<Object?> get props => [patientId, filePaths, descriptions];
}

class DeleteFile extends DossierMedicalEvent {
  final String patientId;
  final String fileId;

  const DeleteFile({required this.patientId, required this.fileId});

  @override
  List<Object?> get props => [patientId, fileId];
}

class UpdateFileDescription extends DossierMedicalEvent {
  final String patientId;
  final String fileId;
  final String description;

  const UpdateFileDescription({
    required this.patientId,
    required this.fileId,
    required this.description,
  });

  @override
  List<Object?> get props => [patientId, fileId, description];
}
