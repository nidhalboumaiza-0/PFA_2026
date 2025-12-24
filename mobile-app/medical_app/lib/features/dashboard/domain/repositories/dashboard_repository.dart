import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats_entity.dart';

abstract class DashboardRepository {
  /// Fetch dashboard statistics for a doctor
  Future<Either<Failure, DashboardStatsEntity>> getDoctorDashboardStats(String doctorId);

  /// Fetch upcoming appointments for a doctor
  Future<Either<Failure, List<AppointmentEntity>>> getUpcomingAppointments(
    String doctorId, {
    int limit = 5,
  });

  /// Fetch all appointments count by status
  Future<Either<Failure, Map<String, int>>> getAppointmentsCountByStatus(String doctorId);

  /// Fetch total patients count
  Future<Either<Failure, int>> getTotalPatientsCount(String doctorId);

  /// Fetch doctor's patients
  Future<Either<Failure, Map<String, dynamic>>> getDoctorPatients(
    String doctorId, {
    int limit = 10,
    String? lastPatientId,
  });
} 