import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDoctorDashboardStatsUseCase {
  final DashboardRepository repository;

  GetDoctorDashboardStatsUseCase(this.repository);

  Future<Either<Failure, DashboardStatsEntity>> call(String doctorId) async {
    return await repository.getDoctorDashboardStats(doctorId);
  }
} 