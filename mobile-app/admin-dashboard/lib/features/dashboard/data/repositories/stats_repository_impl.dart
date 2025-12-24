import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/stats_entity.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/stats_remote_data_source.dart';

class StatsRepositoryImpl implements StatsRepository {
  final StatsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StatsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, StatsEntity>> getStats() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStats = await remoteDataSource.getStats();
        return Right(remoteStats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerDay() async {
    if (await networkInfo.isConnected) {
      try {
        final appointmentsPerDay =
            await remoteDataSource.getAppointmentsPerDay();
        return Right(appointmentsPerDay);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerMonth() async {
    if (await networkInfo.isConnected) {
      try {
        final appointmentsPerMonth =
            await remoteDataSource.getAppointmentsPerMonth();
        return Right(appointmentsPerMonth);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerYear() async {
    if (await networkInfo.isConnected) {
      try {
        final appointmentsPerYear =
            await remoteDataSource.getAppointmentsPerYear();
        return Right(appointmentsPerYear);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<DoctorStatistics>>>
  getTopDoctorsByCompletedAppointments() async {
    if (await networkInfo.isConnected) {
      try {
        final doctors =
            await remoteDataSource.getTopDoctorsByCompletedAppointments();
        return Right(doctors);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<DoctorStatistics>>>
  getTopDoctorsByCancelledAppointments() async {
    if (await networkInfo.isConnected) {
      try {
        final doctors =
            await remoteDataSource.getTopDoctorsByCancelledAppointments();
        return Right(doctors);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<PatientStatistics>>>
  getTopPatientsByCancelledAppointments() async {
    if (await networkInfo.isConnected) {
      try {
        final patients =
            await remoteDataSource.getTopPatientsByCancelledAppointments();
        return Right(patients);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
