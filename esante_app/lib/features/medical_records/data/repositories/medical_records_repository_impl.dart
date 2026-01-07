import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/medical_history_entity.dart';
import '../../domain/repositories/medical_records_repository.dart';
import '../datasources/medical_records_remote_datasource.dart';

class MedicalRecordsRepositoryImpl implements MedicalRecordsRepository {
  final MedicalRecordsRemoteDataSource remoteDataSource;

  MedicalRecordsRepositoryImpl({required this.remoteDataSource});

  void _log(String method, String message) {
    print('[MedicalRecordsRepository.$method] $message');
  }

  @override
  Future<Either<Failure, MedicalHistoryEntity>> getPatientMedicalHistory({
    required String patientId,
  }) async {
    _log('getPatientMedicalHistory', 'Getting history for patient: $patientId');
    return _handleRequest(() =>
        remoteDataSource.getPatientMedicalHistory(patientId: patientId));
  }

  @override
  Future<Either<Failure, MedicalHistoryEntity>> getMyMedicalHistory() async {
    _log('getMyMedicalHistory', 'Getting my medical history');
    return _handleRequest(() => remoteDataSource.getMyMedicalHistory());
  }

  Future<Either<Failure, T>> _handleRequest<T>(
      Future<T> Function() request) async {
    try {
      final result = await request();
      return Right(result);
    } on NetworkException {
      _log('_handleRequest', 'NetworkException');
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      _log('_handleRequest', 'ServerException: ${e.message}');
      return Left(ServerFailure(
        code: e.code,
        message: e.message,
      ));
    } catch (e) {
      _log('_handleRequest', 'Unknown error: $e');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred: ${e.toString()}',
      ));
    }
  }
}
