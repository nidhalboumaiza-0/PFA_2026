import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class RequestAppointmentUseCase
    implements UseCase<AppointmentEntity, RequestAppointmentParams> {
  final AppointmentRepository repository;

  RequestAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      RequestAppointmentParams params) {
    return repository.requestAppointment(
      doctorId: params.doctorId,
      appointmentDate: params.appointmentDate,
      appointmentTime: params.appointmentTime,
      reason: params.reason,
      notes: params.notes,
    );
  }
}

class RequestAppointmentParams extends Equatable {
  final String doctorId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String? reason;
  final String? notes;

  const RequestAppointmentParams({
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.reason,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [doctorId, appointmentDate, appointmentTime, reason, notes];
}
