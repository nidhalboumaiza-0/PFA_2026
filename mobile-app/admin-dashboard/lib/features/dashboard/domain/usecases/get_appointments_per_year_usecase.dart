import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/stats_repository.dart';

class GetAppointmentsPerYearUseCase implements UseCase<Map<String, int>> {
  final StatsRepository repository;

  GetAppointmentsPerYearUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getAppointmentsPerYear();
  }
}
