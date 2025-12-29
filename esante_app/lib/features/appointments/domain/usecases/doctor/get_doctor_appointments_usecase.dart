import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class GetDoctorAppointmentsUseCase
    implements UseCase<List<AppointmentEntity>, GetDoctorAppointmentsParams> {
  final AppointmentRepository repository;

  GetDoctorAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(
      GetDoctorAppointmentsParams params) {
    return repository.getDoctorAppointments(
      status: params.status,
      date: params.date,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetDoctorAppointmentsParams extends Equatable {
  final String? status;
  final DateTime? date;
  final int page;
  final int limit;

  const GetDoctorAppointmentsParams({
    this.status,
    this.date,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, date, page, limit];
}
