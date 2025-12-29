import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/appointment_repository.dart';

class GetAppointmentStatisticsUseCase
    implements UseCase<AppointmentStatistics, NoParams> {
  final AppointmentRepository repository;

  GetAppointmentStatisticsUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentStatistics>> call(NoParams params) {
    return repository.getAppointmentStatistics();
  }
}
