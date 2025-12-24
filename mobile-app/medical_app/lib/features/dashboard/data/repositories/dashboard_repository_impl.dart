import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardStatsEntity>> getDoctorDashboardStats(
    String doctorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dashboardStats = await remoteDataSource.getDoctorDashboardStats(
          doctorId,
        );
        return Right(dashboardStats);
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
  Future<Either<Failure, Map<String, int>>> getAppointmentsCountByStatus(
    String doctorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final appointmentsCount = await remoteDataSource
            .getAppointmentsCountByStatus(doctorId);
        return Right(appointmentsCount);
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
  Future<Either<Failure, List<AppointmentEntity>>> getUpcomingAppointments(
    String doctorId, {
    int limit = 5,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final appointments = await remoteDataSource.getUpcomingAppointments(
          doctorId,
          limit: limit,
        );

        // Convert RendezVousModel to AppointmentEntity
        final appointmentEntities =
            appointments
                .map(
                  (rdv) => AppointmentEntity(
                    id: rdv.id ?? '',
                    patientId: rdv.patient,
                    patientName:
                        '${rdv.patientName ?? ''} ${rdv.patientLastName ?? ''}',
                    appointmentDate: rdv.startDate,
                    status: rdv.status,
                    appointmentType: rdv.serviceName,
                  ),
                )
                .toList();

        return Right(appointmentEntities);
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
  Future<Either<Failure, int>> getTotalPatientsCount(String doctorId) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getTotalPatientsCount(doctorId);
        return Right(count);
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
  Future<Either<Failure, Map<String, dynamic>>> getDoctorPatients(
    String doctorId, {
    int limit = 10,
    String? lastPatientId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getDoctorPatients(
          doctorId,
          limit: limit,
          lastPatientId: lastPatientId,
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
}
