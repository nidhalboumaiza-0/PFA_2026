part of 'medical_records_bloc.dart';

abstract class MedicalRecordsState extends Equatable {
  const MedicalRecordsState();

  @override
  List<Object?> get props => [];
}

class MedicalRecordsInitial extends MedicalRecordsState {}

// ==================== LOADING STATES ====================

class MedicalRecordsLoading extends MedicalRecordsState {}

class ConsultationLoading extends MedicalRecordsState {}

class DocumentLoading extends MedicalRecordsState {}

class DocumentUploading extends MedicalRecordsState {
  final double progress;

  const DocumentUploading({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

// ==================== CONSULTATION SUCCESS STATES ====================

class ConsultationCreated extends MedicalRecordsState {
  final ConsultationEntity consultation;

  const ConsultationCreated({required this.consultation});

  @override
  List<Object?> get props => [consultation];
}

class ConsultationLoaded extends MedicalRecordsState {
  final ConsultationEntity consultation;

  const ConsultationLoaded({required this.consultation});

  @override
  List<Object?> get props => [consultation];
}

class ConsultationUpdated extends MedicalRecordsState {
  final ConsultationEntity consultation;

  const ConsultationUpdated({required this.consultation});

  @override
  List<Object?> get props => [consultation];
}

class ConsultationFullDetailsLoaded extends MedicalRecordsState {
  final ConsultationEntity consultation;

  const ConsultationFullDetailsLoaded({required this.consultation});

  @override
  List<Object?> get props => [consultation];
}

class PatientTimelineLoaded extends MedicalRecordsState {
  final List<TimelineEventEntity> timeline;
  final int page;
  final bool hasMore;

  const PatientTimelineLoaded({
    required this.timeline,
    this.page = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [timeline, page, hasMore];
}

class PatientHistorySearched extends MedicalRecordsState {
  final List<ConsultationEntity> consultations;

  const PatientHistorySearched({required this.consultations});

  @override
  List<Object?> get props => [consultations];
}

class DoctorConsultationsLoaded extends MedicalRecordsState {
  final List<ConsultationEntity> consultations;
  final int page;
  final bool hasMore;

  const DoctorConsultationsLoaded({
    required this.consultations,
    this.page = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [consultations, page, hasMore];
}

class MyMedicalHistoryLoaded extends MedicalRecordsState {
  final List<ConsultationEntity> consultations;
  final int page;
  final bool hasMore;

  const MyMedicalHistoryLoaded({
    required this.consultations,
    this.page = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [consultations, page, hasMore];
}

class ConsultationStatisticsLoaded extends MedicalRecordsState {
  final ConsultationStatisticsEntity statistics;

  const ConsultationStatisticsLoaded({required this.statistics});

  @override
  List<Object?> get props => [statistics];
}

// ==================== DOCUMENT SUCCESS STATES ====================

class DocumentUploaded extends MedicalRecordsState {
  final MedicalDocumentEntity document;

  const DocumentUploaded({required this.document});

  @override
  List<Object?> get props => [document];
}

class DocumentLoaded extends MedicalRecordsState {
  final MedicalDocumentEntity document;

  const DocumentLoaded({required this.document});

  @override
  List<Object?> get props => [document];
}

class PatientDocumentsLoaded extends MedicalRecordsState {
  final List<MedicalDocumentEntity> documents;
  final int page;
  final bool hasMore;

  const PatientDocumentsLoaded({
    required this.documents,
    this.page = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [documents, page, hasMore];
}

class MyDocumentsLoaded extends MedicalRecordsState {
  final List<MedicalDocumentEntity> documents;
  final int page;
  final bool hasMore;

  const MyDocumentsLoaded({
    required this.documents,
    this.page = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [documents, page, hasMore];
}

class ConsultationDocumentsLoaded extends MedicalRecordsState {
  final List<MedicalDocumentEntity> documents;

  const ConsultationDocumentsLoaded({required this.documents});

  @override
  List<Object?> get props => [documents];
}

class DocumentUpdated extends MedicalRecordsState {
  final MedicalDocumentEntity document;

  const DocumentUpdated({required this.document});

  @override
  List<Object?> get props => [document];
}

class DocumentDeleted extends MedicalRecordsState {
  final String documentId;

  const DocumentDeleted({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

class DocumentDownloaded extends MedicalRecordsState {
  final String downloadUrl;

  const DocumentDownloaded({required this.downloadUrl});

  @override
  List<Object?> get props => [downloadUrl];
}

class DocumentSharingUpdated extends MedicalRecordsState {
  final MedicalDocumentEntity document;

  const DocumentSharingUpdated({required this.document});

  @override
  List<Object?> get props => [document];
}

class DocumentStatisticsLoaded extends MedicalRecordsState {
  final DocumentStatisticsEntity statistics;

  const DocumentStatisticsLoaded({required this.statistics});

  @override
  List<Object?> get props => [statistics];
}

// ==================== ERROR STATES ====================

class MedicalRecordsError extends MedicalRecordsState {
  final String message;

  const MedicalRecordsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ConsultationError extends MedicalRecordsState {
  final String message;

  const ConsultationError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DocumentError extends MedicalRecordsState {
  final String message;

  const DocumentError({required this.message});

  @override
  List<Object?> get props => [message];
}
