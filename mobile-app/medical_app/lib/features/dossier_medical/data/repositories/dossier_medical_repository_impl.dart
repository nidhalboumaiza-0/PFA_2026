import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/dossier_medical/data/datasources/dossier_medical_remote_datasource.dart';
import 'package:medical_app/features/dossier_medical/domain/entities/dossier_medical_entity.dart';
import 'package:medical_app/features/dossier_medical/domain/repositories/dossier_medical_repository.dart';

class DossierMedicalRepositoryImpl implements DossierMedicalRepository {
  final DossierMedicalRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DossierMedicalRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DossierMedicalEntity>> getDossierMedical(
    String patientId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteDossier = await remoteDataSource.getDossierMedical(
          patientId,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DossierMedicalEntity>> addFileToDossier(
    String patientId,
    String filePath,
    String description,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final file = File(filePath);
        if (!file.existsSync()) {
          return const Left(FileFailure(message: 'File does not exist'));
        }

        final remoteDossier = await remoteDataSource.addFileToDossier(
          patientId,
          file,
          description,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(FileFailure(message: 'Error handling file: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, DossierMedicalEntity>> addFilesToDossier(
    String patientId,
    List<String> filePaths,
    Map<String, String> descriptions,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final files = <File>[];
        for (final filePath in filePaths) {
          final file = File(filePath);
          if (!file.existsSync()) {
            return Left(FileFailure(message: 'File does not exist: $filePath'));
          }
          files.add(file);
        }

        final remoteDossier = await remoteDataSource.addFilesToDossier(
          patientId,
          files,
          descriptions,
        );
        return Right(remoteDossier);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(FileFailure(message: 'Error handling files: $e'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFile(
    String patientId,
    String fileId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteFile(patientId, fileId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateFileDescription(
          patientId,
          fileId,
          description,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasDossierMedical(String patientId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.hasDossierMedical(patientId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No Internet connection'));
    }
  }
}
