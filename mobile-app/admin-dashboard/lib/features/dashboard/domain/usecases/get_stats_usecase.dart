import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stats_entity.dart';
import '../repositories/stats_repository.dart';

class GetStatsUseCase implements UseCase<StatsEntity> {
  final StatsRepository repository;

  GetStatsUseCase(this.repository);

  @override
  Future<Either<Failure, StatsEntity>> call() {
    return repository.getStats();
  }
}
