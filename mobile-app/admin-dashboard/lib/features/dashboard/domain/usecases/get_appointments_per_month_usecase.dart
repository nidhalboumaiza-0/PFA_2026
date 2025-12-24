import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/stats_repository.dart';

class GetAppointmentsPerMonthUseCase implements UseCase<Map<String, int>> {
  final StatsRepository repository;

  GetAppointmentsPerMonthUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getAppointmentsPerMonth();
  }
}
