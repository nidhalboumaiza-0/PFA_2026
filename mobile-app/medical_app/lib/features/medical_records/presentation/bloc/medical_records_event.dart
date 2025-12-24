part of 'medical_records_bloc.dart';

abstract class MedicalRecordsEvent extends Equatable {
  const MedicalRecordsEvent();

  @override
  List<Object?> get props => [];
}

// ==================== CONSULTATION EVENTS ====================

class CreateConsultationEvent extends MedicalRecordsEvent {
  final String appointmentId;
  final String chiefComplaint;
  final MedicalNoteEntity medicalNote;
  final String consultationType;
  final bool requiresFollowUp;
  final DateTime? followUpDate;
  final String? followUpNotes;
  final String? referralId;

  const CreateConsultationEvent({
    required this.appointmentId,
    required this.chiefComplaint,
    required this.medicalNote,
    this.consultationType = 'in-person',
    this.requiresFollowUp = false,
    this.followUpDate,
    this.followUpNotes,
    this.referralId,
  });

  @override
  List<Object?> get props => [
        appointmentId,
        chiefComplaint,
        medicalNote,
        consultationType,
        requiresFollowUp,
        followUpDate,
        followUpNotes,
        referralId,
      ];
}

class GetConsultationByIdEvent extends MedicalRecordsEvent {
  final String consultationId;

  const GetConsultationByIdEvent({required this.consultationId});

  @override
  List<Object?> get props => [consultationId];
}

class GetConsultationFullDetailsEvent extends MedicalRecordsEvent {
  final String consultationId;

  const GetConsultationFullDetailsEvent({required this.consultationId});

  @override
  List<Object?> get props => [consultationId];
}

class UpdateConsultationEvent extends MedicalRecordsEvent {
  final String consultationId;
  final String? chiefComplaint;
  final MedicalNoteEntity? medicalNote;
  final bool? requiresFollowUp;
  final DateTime? followUpDate;
  final String? followUpNotes;
  final String? status;

  const UpdateConsultationEvent({
    required this.consultationId,
    this.chiefComplaint,
    this.medicalNote,
    this.requiresFollowUp,
    this.followUpDate,
    this.followUpNotes,
    this.status,
  });

  @override
  List<Object?> get props => [
        consultationId,
        chiefComplaint,
        medicalNote,
        requiresFollowUp,
        followUpDate,
        followUpNotes,
        status,
      ];
}

class GetPatientTimelineEvent extends MedicalRecordsEvent {
  final String patientId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? filterDoctorId;
  final int page;
  final int limit;

  const GetPatientTimelineEvent({
    required this.patientId,
    this.startDate,
    this.endDate,
    this.filterDoctorId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [patientId, startDate, endDate, filterDoctorId, page, limit];
}

class SearchPatientHistoryEvent extends MedicalRecordsEvent {
  final String patientId;
  final String? query;
  final DateTime? startDate;
  final DateTime? endDate;

  const SearchPatientHistoryEvent({
    required this.patientId,
    this.query,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [patientId, query, startDate, endDate];
}

class GetDoctorConsultationsEvent extends MedicalRecordsEvent {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const GetDoctorConsultationsEvent({
    this.status,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, startDate, endDate, page, limit];
}

class GetMyMedicalHistoryEvent extends MedicalRecordsEvent {
  final int page;
  final int limit;

  const GetMyMedicalHistoryEvent({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

class GetConsultationStatisticsEvent extends MedicalRecordsEvent {
  const GetConsultationStatisticsEvent();
}

// ==================== DOCUMENT EVENTS ====================

class UploadDocumentEvent extends MedicalRecordsEvent {
  final File file;
  final String documentType;
  final String title;
  final String? description;
  final String? consultationId;
  final DateTime? documentDate;
  final List<String>? tags;

  const UploadDocumentEvent({
    required this.file,
    required this.documentType,
    required this.title,
    this.description,
    this.consultationId,
    this.documentDate,
    this.tags,
  });

  @override
  List<Object?> get props => [
        file,
        documentType,
        title,
        description,
        consultationId,
        documentDate,
        tags,
      ];
}

class GetDocumentByIdEvent extends MedicalRecordsEvent {
  final String documentId;

  const GetDocumentByIdEvent({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

class GetPatientDocumentsEvent extends MedicalRecordsEvent {
  final String patientId;
  final String? documentType;
  final int page;
  final int limit;

  const GetPatientDocumentsEvent({
    required this.patientId,
    this.documentType,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [patientId, documentType, page, limit];
}

class GetMyDocumentsEvent extends MedicalRecordsEvent {
  final String? documentType;
  final int page;
  final int limit;

  const GetMyDocumentsEvent({
    this.documentType,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [documentType, page, limit];
}

class GetConsultationDocumentsEvent extends MedicalRecordsEvent {
  final String consultationId;

  const GetConsultationDocumentsEvent({required this.consultationId});

  @override
  List<Object?> get props => [consultationId];
}

class UpdateDocumentEvent extends MedicalRecordsEvent {
  final String documentId;
  final String? title;
  final String? description;
  final List<String>? tags;

  const UpdateDocumentEvent({
    required this.documentId,
    this.title,
    this.description,
    this.tags,
  });

  @override
  List<Object?> get props => [documentId, title, description, tags];
}

class DeleteDocumentEvent extends MedicalRecordsEvent {
  final String documentId;

  const DeleteDocumentEvent({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

class DownloadDocumentEvent extends MedicalRecordsEvent {
  final String documentId;

  const DownloadDocumentEvent({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

class UpdateDocumentSharingEvent extends MedicalRecordsEvent {
  final String documentId;
  final bool? isSharedWithAllDoctors;
  final List<String>? sharedWithDoctors;

  const UpdateDocumentSharingEvent({
    required this.documentId,
    this.isSharedWithAllDoctors,
    this.sharedWithDoctors,
  });

  @override
  List<Object?> get props =>
      [documentId, isSharedWithAllDoctors, sharedWithDoctors];
}

class GetDocumentStatisticsEvent extends MedicalRecordsEvent {
  const GetDocumentStatisticsEvent();
}

// ==================== GENERAL EVENTS ====================

class ResetMedicalRecordsStateEvent extends MedicalRecordsEvent {
  const ResetMedicalRecordsStateEvent();
}
