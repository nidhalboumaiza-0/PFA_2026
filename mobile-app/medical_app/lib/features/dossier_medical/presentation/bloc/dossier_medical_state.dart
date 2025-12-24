import 'package:equatable/equatable.dart';
import 'package:medical_app/features/dossier_medical/domain/entities/dossier_medical_entity.dart';

abstract class DossierMedicalState extends Equatable {
  const DossierMedicalState();

  @override
  List<Object?> get props => [];
}

class DossierMedicalInitial extends DossierMedicalState {
  const DossierMedicalInitial();
}

class DossierMedicalLoading extends DossierMedicalState {
  const DossierMedicalLoading();
}

class DossierMedicalLoaded extends DossierMedicalState {
  final DossierMedicalEntity dossier;

  const DossierMedicalLoaded({required this.dossier});

  @override
  List<Object?> get props => [dossier];
}

class DossierMedicalEmpty extends DossierMedicalState {
  final String patientId;

  const DossierMedicalEmpty({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

class DossierMedicalError extends DossierMedicalState {
  final String message;

  const DossierMedicalError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FileUploadLoading extends DossierMedicalState {
  final bool isSingleFile;

  const FileUploadLoading({this.isSingleFile = true});

  @override
  List<Object?> get props => [isSingleFile];
}

class FileUploadSuccess extends DossierMedicalState {
  final DossierMedicalEntity dossier;
  final bool isSingleFile;

  const FileUploadSuccess({required this.dossier, this.isSingleFile = true});

  @override
  List<Object?> get props => [dossier, isSingleFile];
}

class FileUploadError extends DossierMedicalState {
  final String message;
  final bool isSingleFile;

  const FileUploadError({required this.message, this.isSingleFile = true});

  @override
  List<Object?> get props => [message, isSingleFile];
}

class FileDeleteLoading extends DossierMedicalState {
  final String fileId;

  const FileDeleteLoading({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class FileDeleteSuccess extends DossierMedicalState {
  final String fileId;

  const FileDeleteSuccess({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class FileDeleteError extends DossierMedicalState {
  final String message;
  final String fileId;

  const FileDeleteError({required this.message, required this.fileId});

  @override
  List<Object?> get props => [message, fileId];
}

class FileDescriptionUpdateLoading extends DossierMedicalState {
  final String fileId;

  const FileDescriptionUpdateLoading({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class FileDescriptionUpdateSuccess extends DossierMedicalState {
  final String fileId;

  const FileDescriptionUpdateSuccess({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class FileDescriptionUpdateError extends DossierMedicalState {
  final String message;
  final String fileId;

  const FileDescriptionUpdateError({
    required this.message,
    required this.fileId,
  });

  @override
  List<Object?> get props => [message, fileId];
}

class CheckingDossierMedicalStatus extends DossierMedicalState {
  const CheckingDossierMedicalStatus();
}

class DossierMedicalExists extends DossierMedicalState {
  final bool exists;

  const DossierMedicalExists({required this.exists});

  @override
  List<Object?> get props => [exists];
}
