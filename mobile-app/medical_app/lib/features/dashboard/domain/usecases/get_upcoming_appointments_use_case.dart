import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetUpcomingAppointmentsUseCase {
  final DashboardRepository repository;

  GetUpcomingAppointmentsUseCase(this.repository);

  Future<Either<Failure, List<AppointmentEntity>>> call(
    String doctorId, {
    int limit = 5,
  }) async {
    return await repository.getUpcomingAppointments(doctorId, limit: limit);
  }
} 