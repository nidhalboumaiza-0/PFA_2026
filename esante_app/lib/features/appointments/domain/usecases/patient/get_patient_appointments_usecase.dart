import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetPatientAppointmentsUseCase
    implements UseCase<List<AppointmentEntity>, GetPatientAppointmentsParams> {
  final AppointmentRepository repository;

  GetPatientAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(
      GetPatientAppointmentsParams params) {
    return repository.getPatientAppointments(
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetPatientAppointmentsParams extends Equatable {
  final String? status;
  final int page;
  final int limit;

  const GetPatientAppointmentsParams({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}
