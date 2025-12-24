import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stats_entity.dart';
import '../repositories/stats_repository.dart';

class GetTopDoctorsByCompletedAppointmentsUseCase
    implements UseCase<List<DoctorStatistics>> {
  final StatsRepository repository;

  GetTopDoctorsByCompletedAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DoctorStatistics>>> call() {
    return repository.getTopDoctorsByCompletedAppointments();
  }
}
