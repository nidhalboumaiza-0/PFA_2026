import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetAppointmentRequestsUseCase
    implements UseCase<List<AppointmentEntity>, GetAppointmentRequestsParams> {
  final AppointmentRepository repository;

  GetAppointmentRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(
      GetAppointmentRequestsParams params) {
    return repository.getAppointmentRequests(
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetAppointmentRequestsParams extends Equatable {
  final int page;
  final int limit;

  const GetAppointmentRequestsParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}
