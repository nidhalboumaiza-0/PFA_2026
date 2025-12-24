import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';

/// Repository interface for medical records operations
abstract class MedicalRecordsRepository {
  // ==================== CONSULTATION OPERATIONS ====================

  /// Create a new consultation (doctor only)
  Future<Either<Failure, ConsultationEntity>> createConsultation({
    required String appointmentId,
    required String chiefComplaint,
    required MedicalNoteEntity medicalNote,
    String consultationType = 'in-person',
    bool requiresFollowUp = false,
    DateTime? followUpDate,
    String? followUpNotes,
    String? referralId,
  });

  /// Get consultation by ID
  Future<Either<Failure, ConsultationEntity>> getConsultationById(
      String consultationId);

  /// Update consultation (doctor only)
  Future<Either<Failure, ConsultationEntity>> updateConsultation({
    required String consultationId,
    String? chiefComplaint,
    MedicalNoteEntity? medicalNote,
    bool? requiresFollowUp,
    DateTime? followUpDate,
    String? followUpNotes,
    String? status,
  });

  /// Get consultation with full details (doctor only)
  Future<Either<Failure, ConsultationEntity>> getConsultationFullDetails(
      String consultationId);

  /// Get patient medical timeline (doctor only)
  Future<Either<Failure, List<TimelineEventEntity>>> getPatientTimeline({
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
    String? filterDoctorId,
    int page = 1,
    int limit = 20,
  });

  /// Search patient medical history (doctor only)
  Future<Either<Failure, List<ConsultationEntity>>> searchPatientHistory({
    required String patientId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get doctor's consultations (doctor only)
  Future<Either<Failure, List<ConsultationEntity>>> getDoctorConsultations({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  /// Get my medical history (patient only)
  Future<Either<Failure, List<ConsultationEntity>>> getMyMedicalHistory({
    int page = 1,
    int limit = 20,
  });

  /// Get consultation statistics (doctor only)
  Future<Either<Failure, ConsultationStatisticsEntity>>
      getConsultationStatistics();

  // ==================== DOCUMENT OPERATIONS ====================

  /// Upload a document
  Future<Either<Failure, MedicalDocumentEntity>> uploadDocument({
    required File file,
    required String documentType,
    required String title,
    String? description,
    String? consultationId,
    DateTime? documentDate,
    List<String>? tags,
  });

  /// Get document by ID
  Future<Either<Failure, MedicalDocumentEntity>> getDocumentById(
      String documentId);

  /// Get patient's documents (doctor only)
  Future<Either<Failure, List<MedicalDocumentEntity>>> getPatientDocuments({
    required String patientId,
    String? documentType,
    int page = 1,
    int limit = 20,
  });

  /// Get my documents (patient only)
  Future<Either<Failure, List<MedicalDocumentEntity>>> getMyDocuments({
    String? documentType,
    int page = 1,
    int limit = 20,
  });

  /// Get consultation documents
  Future<Either<Failure, List<MedicalDocumentEntity>>> getConsultationDocuments(
      String consultationId);

  /// Update document metadata
  Future<Either<Failure, MedicalDocumentEntity>> updateDocument({
    required String documentId,
    String? title,
    String? description,
    List<String>? tags,
  });

  /// Delete document
  Future<Either<Failure, Unit>> deleteDocument(String documentId);

  /// Download document - returns download URL
  Future<Either<Failure, String>> downloadDocument(String documentId);

  /// Update document sharing (patient only)
  Future<Either<Failure, MedicalDocumentEntity>> updateDocumentSharing({
    required String documentId,
    bool? isSharedWithAllDoctors,
    List<String>? sharedWithDoctors,
  });

  /// Get document statistics
  Future<Either<Failure, DocumentStatisticsEntity>> getDocumentStatistics();
}
