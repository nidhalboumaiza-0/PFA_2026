import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../datasources/prescription_remote_datasource.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PrescriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PrescriptionEntity>> createPrescription(
    PrescriptionEntity prescription,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createPrescription(prescription);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> editPrescription(
    PrescriptionEntity prescription,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.editPrescription(prescription);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getPatientPrescriptions(
    String patientId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPatientPrescriptions(
          patientId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getDoctorPrescriptions(
    String doctorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getDoctorPrescriptions(doctorId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(
    String prescriptionId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPrescriptionById(
          prescriptionId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity?>> getPrescriptionByAppointmentId(
    String appointmentId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPrescriptionByAppointmentId(
          appointmentId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePrescriptionStatus(
    String prescriptionId,
    String status,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePrescriptionStatus(prescriptionId, status);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerMessageFailure(e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
