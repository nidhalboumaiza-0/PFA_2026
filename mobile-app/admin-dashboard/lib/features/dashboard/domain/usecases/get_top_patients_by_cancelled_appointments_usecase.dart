import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stats_entity.dart';
import '../repositories/stats_repository.dart';

class GetTopPatientsByCancelledAppointmentsUseCase
    implements UseCase<List<PatientStatistics>> {
  final StatsRepository repository;

  GetTopPatientsByCancelledAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PatientStatistics>>> call() {
    return repository.getTopPatientsByCancelledAppointments();
  }
}
