import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_remote_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';
import '../models/RendezVous.dart';

class RendezVousRepositoryImpl implements RendezVousRepository {
  final RendezVousRemoteDataSource remoteDataSource;
  final RendezVousLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  RendezVousRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RendezVousEntity>>> getRendezVous({
    String? patientId,
    String? doctorId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final rendezVousModels = await remoteDataSource.getRendezVous(
          patientId: patientId,
          doctorId: doctorId,
        );
        // Convert to entities (though in this case they're already entities as models extend entities)
        final rendezVousEntities = rendezVousModels;
        return Right(rendezVousEntities);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final cachedRendezVous = await localDataSource.getCachedRendezVous();
        return Right(cachedRendezVous);
      } on EmptyCacheException {
        return Left(EmptyCacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> updateRendezVousStatus(
    String rendezVousId,
    String status,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateRendezVousStatus(rendezVousId, status);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> createRendezVous(
    RendezVousEntity rendezVous,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Create model from entity
        final rendezVousModel = RendezVousModel(
          id: rendezVous.id,
          startDate: rendezVous.startDate,
          endDate: rendezVous.endDate,
          serviceName: rendezVous.serviceName,
          patient: rendezVous.patient,
          medecin: rendezVous.medecin,
          status: rendezVous.status,
          motif: rendezVous.motif,
          notes: rendezVous.notes,
          symptoms: rendezVous.symptoms,
          isRated: rendezVous.isRated,
          hasPrescription: rendezVous.hasPrescription,
          createdAt: rendezVous.createdAt,
        );

        await remoteDataSource.createRendezVous(rendezVousModel);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<MedecinEntity>>> getDoctorsBySpecialty(
    String specialty, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final doctors = await remoteDataSource.getDoctorsBySpecialty(
          specialty,
          startDate: startDate,
          endDate: endDate,
        );
        return Right(doctors);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, RendezVousEntity>> getRendezVousDetails(
    String rendezVousId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final appointment = await remoteDataSource.getRendezVousDetails(
          rendezVousId,
        );
        return Right(appointment);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelAppointment(String rendezVousId, {String? reason}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cancelAppointment(rendezVousId, reason: reason);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> rateDoctor(
    String appointmentId,
    double rating,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.rateDoctor(appointmentId, rating);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<RendezVousEntity>>> getDoctorAppointmentsForDay(
    String doctorId,
    DateTime date,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final appointments = await remoteDataSource.getDoctorAppointmentsForDay(
          doctorId,
          date,
        );
        return Right(appointments);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptAppointment(String rendezVousId, {String? notes}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.acceptAppointment(rendezVousId, notes: notes);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> refuseAppointment(String rendezVousId, {String? reason}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.refuseAppointment(rendezVousId, reason: reason);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> completeAppointment(String rendezVousId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.completeAppointment(rendezVousId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<RendezVousEntity>>> getAppointmentRequests() async {
    if (await networkInfo.isConnected) {
      try {
        final appointments = await remoteDataSource.getAppointmentRequests();
        return Right(appointments);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDoctorAvailability() async {
    if (await networkInfo.isConnected) {
      try {
        final availability = await remoteDataSource.getDoctorAvailability();
        return Right(availability);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setDoctorAvailability(Map<String, dynamic> availability) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setDoctorAvailability(availability);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> viewDoctorAvailability(String doctorId, {DateTime? date}) async {
    if (await networkInfo.isConnected) {
      try {
        final availability = await remoteDataSource.viewDoctorAvailability(doctorId, date: date);
        return Right(availability);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAppointmentStatistics() async {
    if (await networkInfo.isConnected) {
      try {
        final statistics = await remoteDataSource.getAppointmentStatistics();
        return Right(statistics);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  // ==================== RESCHEDULE METHODS ====================

  @override
  Future<Either<Failure, Unit>> rescheduleAppointment(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.rescheduleAppointment(
          appointmentId,
          newDate: newDate,
          newTime: newTime,
          reason: reason,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> requestReschedule(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.requestReschedule(
          appointmentId,
          newDate: newDate,
          newTime: newTime,
          reason: reason,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> approveReschedule(String appointmentId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.approveReschedule(appointmentId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectReschedule(String appointmentId, {String? reason}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.rejectReschedule(appointmentId, reason: reason);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
