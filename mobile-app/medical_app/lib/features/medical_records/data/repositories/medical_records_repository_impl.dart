import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/medical_records/data/datasources/medical_records_remote_datasource.dart';
import 'package:medical_app/features/medical_records/data/models/consultation_model.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';
import 'package:medical_app/features/medical_records/domain/repositories/medical_records_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalRecordsRepositoryImpl implements MedicalRecordsRepository {
  final MedicalRecordsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SharedPreferences sharedPreferences;

  static const String _tokenKey = 'TOKEN';

  MedicalRecordsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.sharedPreferences,
  });

  String? _getToken() {
    return sharedPreferences.getString(_tokenKey);
  }

  // ==================== CONSULTATION OPERATIONS ====================

  @override
  Future<Either<Failure, ConsultationEntity>> createConsultation({
    required String appointmentId,
    required String chiefComplaint,
    required MedicalNoteEntity medicalNote,
    String consultationType = 'in-person',
    bool requiresFollowUp = false,
    DateTime? followUpDate,
    String? followUpNotes,
    String? referralId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final consultationData = ConsultationModel.createRequest(
        appointmentId: appointmentId,
        chiefComplaint: chiefComplaint,
        medicalNote: MedicalNoteModel(
          symptoms: medicalNote.symptoms,
          diagnosis: medicalNote.diagnosis,
          physicalExamination: medicalNote.physicalExamination,
          vitalSigns: medicalNote.vitalSigns != null
              ? VitalSignsModel(
                  temperature: medicalNote.vitalSigns!.temperature,
                  bloodPressure: medicalNote.vitalSigns!.bloodPressure,
                  heartRate: medicalNote.vitalSigns!.heartRate,
                  respiratoryRate: medicalNote.vitalSigns!.respiratoryRate,
                  oxygenSaturation: medicalNote.vitalSigns!.oxygenSaturation,
                  weight: medicalNote.vitalSigns!.weight,
                  height: medicalNote.vitalSigns!.height,
                )
              : null,
          labResults: medicalNote.labResults,
          additionalNotes: medicalNote.additionalNotes,
        ),
        consultationType: consultationType,
        requiresFollowUp: requiresFollowUp,
        followUpDate: followUpDate,
        followUpNotes: followUpNotes,
        referralId: referralId,
      );

      final result = await remoteDataSource.createConsultation(
        token: token,
        consultationData: consultationData,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> getConsultationById(
      String consultationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getConsultationById(
        token: token,
        consultationId: consultationId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> updateConsultation({
    required String consultationId,
    String? chiefComplaint,
    MedicalNoteEntity? medicalNote,
    bool? requiresFollowUp,
    DateTime? followUpDate,
    String? followUpNotes,
    String? status,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final updateData = <String, dynamic>{
        if (chiefComplaint != null) 'chiefComplaint': chiefComplaint,
        if (medicalNote != null)
          'medicalNote': MedicalNoteModel(
            symptoms: medicalNote.symptoms,
            diagnosis: medicalNote.diagnosis,
            physicalExamination: medicalNote.physicalExamination,
            labResults: medicalNote.labResults,
            additionalNotes: medicalNote.additionalNotes,
          ).toJson(),
        if (requiresFollowUp != null) 'requiresFollowUp': requiresFollowUp,
        if (followUpDate != null) 'followUpDate': followUpDate.toIso8601String(),
        if (followUpNotes != null) 'followUpNotes': followUpNotes,
        if (status != null) 'status': status,
      };

      final result = await remoteDataSource.updateConsultation(
        token: token,
        consultationId: consultationId,
        updateData: updateData,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultationEntity>> getConsultationFullDetails(
      String consultationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getConsultationFullDetails(
        token: token,
        consultationId: consultationId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimelineEventEntity>>> getPatientTimeline({
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
    String? filterDoctorId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getPatientTimeline(
        token: token,
        patientId: patientId,
        startDate: startDate,
        endDate: endDate,
        filterDoctorId: filterDoctorId,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConsultationEntity>>> searchPatientHistory({
    required String patientId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.searchPatientHistory(
        token: token,
        patientId: patientId,
        query: query,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConsultationEntity>>> getDoctorConsultations({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getDoctorConsultations(
        token: token,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConsultationEntity>>> getMyMedicalHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getMyMedicalHistory(
        token: token,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultationStatisticsEntity>>
      getConsultationStatistics() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result =
          await remoteDataSource.getConsultationStatistics(token: token);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ==================== DOCUMENT OPERATIONS ====================

  @override
  Future<Either<Failure, MedicalDocumentEntity>> uploadDocument({
    required File file,
    required String documentType,
    required String title,
    String? description,
    String? consultationId,
    DateTime? documentDate,
    List<String>? tags,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.uploadDocument(
        token: token,
        file: file,
        documentType: documentType,
        title: title,
        description: description,
        consultationId: consultationId,
        documentDate: documentDate,
        tags: tags,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalDocumentEntity>> getDocumentById(
      String documentId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getDocumentById(
        token: token,
        documentId: documentId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedicalDocumentEntity>>> getPatientDocuments({
    required String patientId,
    String? documentType,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getPatientDocuments(
        token: token,
        patientId: patientId,
        documentType: documentType,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedicalDocumentEntity>>> getMyDocuments({
    String? documentType,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getMyDocuments(
        token: token,
        documentType: documentType,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedicalDocumentEntity>>> getConsultationDocuments(
      String consultationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getConsultationDocuments(
        token: token,
        consultationId: consultationId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalDocumentEntity>> updateDocument({
    required String documentId,
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.updateDocument(
        token: token,
        documentId: documentId,
        title: title,
        description: description,
        tags: tags,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDocument(String documentId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      await remoteDataSource.deleteDocument(
        token: token,
        documentId: documentId,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadDocument(String documentId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.downloadDocument(
        token: token,
        documentId: documentId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalDocumentEntity>> updateDocumentSharing({
    required String documentId,
    bool? isSharedWithAllDoctors,
    List<String>? sharedWithDoctors,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.updateDocumentSharing(
        token: token,
        documentId: documentId,
        isSharedWithAllDoctors: isSharedWithAllDoctors,
        sharedWithDoctors: sharedWithDoctors,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DocumentStatisticsEntity>>
      getDocumentStatistics() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result =
          await remoteDataSource.getDocumentStatistics(token: token);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
