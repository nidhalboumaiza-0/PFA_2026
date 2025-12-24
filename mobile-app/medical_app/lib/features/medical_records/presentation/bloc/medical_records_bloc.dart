import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';
import 'package:medical_app/features/medical_records/domain/repositories/medical_records_repository.dart';

part 'medical_records_event.dart';
part 'medical_records_state.dart';

class MedicalRecordsBloc
    extends Bloc<MedicalRecordsEvent, MedicalRecordsState> {
  final MedicalRecordsRepository repository;

  MedicalRecordsBloc({required this.repository})
      : super(MedicalRecordsInitial()) {
    // Consultation events
    on<CreateConsultationEvent>(_onCreateConsultation);
    on<GetConsultationByIdEvent>(_onGetConsultationById);
    on<GetConsultationFullDetailsEvent>(_onGetConsultationFullDetails);
    on<UpdateConsultationEvent>(_onUpdateConsultation);
    on<GetPatientTimelineEvent>(_onGetPatientTimeline);
    on<SearchPatientHistoryEvent>(_onSearchPatientHistory);
    on<GetDoctorConsultationsEvent>(_onGetDoctorConsultations);
    on<GetMyMedicalHistoryEvent>(_onGetMyMedicalHistory);
    on<GetConsultationStatisticsEvent>(_onGetConsultationStatistics);

    // Document events
    on<UploadDocumentEvent>(_onUploadDocument);
    on<GetDocumentByIdEvent>(_onGetDocumentById);
    on<GetPatientDocumentsEvent>(_onGetPatientDocuments);
    on<GetMyDocumentsEvent>(_onGetMyDocuments);
    on<GetConsultationDocumentsEvent>(_onGetConsultationDocuments);
    on<UpdateDocumentEvent>(_onUpdateDocument);
    on<DeleteDocumentEvent>(_onDeleteDocument);
    on<DownloadDocumentEvent>(_onDownloadDocument);
    on<UpdateDocumentSharingEvent>(_onUpdateDocumentSharing);
    on<GetDocumentStatisticsEvent>(_onGetDocumentStatistics);

    // General events
    on<ResetMedicalRecordsStateEvent>(_onResetState);
  }

  // ==================== CONSULTATION HANDLERS ====================

  Future<void> _onCreateConsultation(
    CreateConsultationEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(ConsultationLoading());

    final result = await repository.createConsultation(
      appointmentId: event.appointmentId,
      chiefComplaint: event.chiefComplaint,
      medicalNote: event.medicalNote,
      consultationType: event.consultationType,
      requiresFollowUp: event.requiresFollowUp,
      followUpDate: event.followUpDate,
      followUpNotes: event.followUpNotes,
      referralId: event.referralId,
    );

    result.fold(
      (failure) => emit(ConsultationError(message: failure.message)),
      (consultation) => emit(ConsultationCreated(consultation: consultation)),
    );
  }

  Future<void> _onGetConsultationById(
    GetConsultationByIdEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(ConsultationLoading());

    final result = await repository.getConsultationById(event.consultationId);

    result.fold(
      (failure) => emit(ConsultationError(message: failure.message)),
      (consultation) => emit(ConsultationLoaded(consultation: consultation)),
    );
  }

  Future<void> _onGetConsultationFullDetails(
    GetConsultationFullDetailsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(ConsultationLoading());

    final result =
        await repository.getConsultationFullDetails(event.consultationId);

    result.fold(
      (failure) => emit(ConsultationError(message: failure.message)),
      (consultation) =>
          emit(ConsultationFullDetailsLoaded(consultation: consultation)),
    );
  }

  Future<void> _onUpdateConsultation(
    UpdateConsultationEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(ConsultationLoading());

    final result = await repository.updateConsultation(
      consultationId: event.consultationId,
      chiefComplaint: event.chiefComplaint,
      medicalNote: event.medicalNote,
      requiresFollowUp: event.requiresFollowUp,
      followUpDate: event.followUpDate,
      followUpNotes: event.followUpNotes,
      status: event.status,
    );

    result.fold(
      (failure) => emit(ConsultationError(message: failure.message)),
      (consultation) => emit(ConsultationUpdated(consultation: consultation)),
    );
  }

  Future<void> _onGetPatientTimeline(
    GetPatientTimelineEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());

    final result = await repository.getPatientTimeline(
      patientId: event.patientId,
      startDate: event.startDate,
      endDate: event.endDate,
      filterDoctorId: event.filterDoctorId,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MedicalRecordsError(message: failure.message)),
      (timeline) => emit(PatientTimelineLoaded(
        timeline: timeline,
        page: event.page,
        hasMore: timeline.length >= event.limit,
      )),
    );
  }

  Future<void> _onSearchPatientHistory(
    SearchPatientHistoryEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());

    final result = await repository.searchPatientHistory(
      patientId: event.patientId,
      query: event.query,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(MedicalRecordsError(message: failure.message)),
      (consultations) =>
          emit(PatientHistorySearched(consultations: consultations)),
    );
  }

  Future<void> _onGetDoctorConsultations(
    GetDoctorConsultationsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());

    final result = await repository.getDoctorConsultations(
      status: event.status,
      startDate: event.startDate,
      endDate: event.endDate,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MedicalRecordsError(message: failure.message)),
      (consultations) => emit(DoctorConsultationsLoaded(
        consultations: consultations,
        page: event.page,
        hasMore: consultations.length >= event.limit,
      )),
    );
  }

  Future<void> _onGetMyMedicalHistory(
    GetMyMedicalHistoryEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());

    final result = await repository.getMyMedicalHistory(
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MedicalRecordsError(message: failure.message)),
      (consultations) => emit(MyMedicalHistoryLoaded(
        consultations: consultations,
        page: event.page,
        hasMore: consultations.length >= event.limit,
      )),
    );
  }

  Future<void> _onGetConsultationStatistics(
    GetConsultationStatisticsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(MedicalRecordsLoading());

    final result = await repository.getConsultationStatistics();

    result.fold(
      (failure) => emit(MedicalRecordsError(message: failure.message)),
      (statistics) =>
          emit(ConsultationStatisticsLoaded(statistics: statistics)),
    );
  }

  // ==================== DOCUMENT HANDLERS ====================

  Future<void> _onUploadDocument(
    UploadDocumentEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(const DocumentUploading(progress: 0.0));

    final result = await repository.uploadDocument(
      file: event.file,
      documentType: event.documentType,
      title: event.title,
      description: event.description,
      consultationId: event.consultationId,
      documentDate: event.documentDate,
      tags: event.tags,
    );

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (document) => emit(DocumentUploaded(document: document)),
    );
  }

  Future<void> _onGetDocumentById(
    GetDocumentByIdEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.getDocumentById(event.documentId);

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (document) => emit(DocumentLoaded(document: document)),
    );
  }

  Future<void> _onGetPatientDocuments(
    GetPatientDocumentsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.getPatientDocuments(
      patientId: event.patientId,
      documentType: event.documentType,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (documents) => emit(PatientDocumentsLoaded(
        documents: documents,
        page: event.page,
        hasMore: documents.length >= event.limit,
      )),
    );
  }

  Future<void> _onGetMyDocuments(
    GetMyDocumentsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.getMyDocuments(
      documentType: event.documentType,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (documents) => emit(MyDocumentsLoaded(
        documents: documents,
        page: event.page,
        hasMore: documents.length >= event.limit,
      )),
    );
  }

  Future<void> _onGetConsultationDocuments(
    GetConsultationDocumentsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result =
        await repository.getConsultationDocuments(event.consultationId);

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (documents) => emit(ConsultationDocumentsLoaded(documents: documents)),
    );
  }

  Future<void> _onUpdateDocument(
    UpdateDocumentEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.updateDocument(
      documentId: event.documentId,
      title: event.title,
      description: event.description,
      tags: event.tags,
    );

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (document) => emit(DocumentUpdated(document: document)),
    );
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.deleteDocument(event.documentId);

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (_) => emit(DocumentDeleted(documentId: event.documentId)),
    );
  }

  Future<void> _onDownloadDocument(
    DownloadDocumentEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.downloadDocument(event.documentId);

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (downloadUrl) => emit(DocumentDownloaded(downloadUrl: downloadUrl)),
    );
  }

  Future<void> _onUpdateDocumentSharing(
    UpdateDocumentSharingEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.updateDocumentSharing(
      documentId: event.documentId,
      isSharedWithAllDoctors: event.isSharedWithAllDoctors,
      sharedWithDoctors: event.sharedWithDoctors,
    );

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (document) => emit(DocumentSharingUpdated(document: document)),
    );
  }

  Future<void> _onGetDocumentStatistics(
    GetDocumentStatisticsEvent event,
    Emitter<MedicalRecordsState> emit,
  ) async {
    emit(DocumentLoading());

    final result = await repository.getDocumentStatistics();

    result.fold(
      (failure) => emit(DocumentError(message: failure.message)),
      (statistics) => emit(DocumentStatisticsLoaded(statistics: statistics)),
    );
  }

  // ==================== GENERAL HANDLERS ====================

  void _onResetState(
    ResetMedicalRecordsStateEvent event,
    Emitter<MedicalRecordsState> emit,
  ) {
    emit(MedicalRecordsInitial());
  }
}
