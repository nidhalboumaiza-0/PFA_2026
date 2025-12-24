import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/stats_entity.dart';

abstract class StatsRepository {
  Future<Either<Failure, StatsEntity>> getStats();
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerDay();
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerMonth();
  Future<Either<Failure, Map<String, int>>> getAppointmentsPerYear();
  Future<Either<Failure, List<DoctorStatistics>>>
  getTopDoctorsByCompletedAppointments();
  Future<Either<Failure, List<DoctorStatistics>>>
  getTopDoctorsByCancelledAppointments();
  Future<Either<Failure, List<PatientStatistics>>>
  getTopPatientsByCancelledAppointments();
}
