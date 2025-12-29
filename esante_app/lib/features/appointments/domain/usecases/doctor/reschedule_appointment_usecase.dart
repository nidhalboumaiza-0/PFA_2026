import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class RescheduleAppointmentUseCase
    implements UseCase<AppointmentEntity, RescheduleAppointmentParams> {
  final AppointmentRepository repository;

  RescheduleAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      RescheduleAppointmentParams params) {
    return repository.rescheduleAppointment(
      appointmentId: params.appointmentId,
      newDate: params.newDate,
      newTime: params.newTime,
      reason: params.reason,
    );
  }
}

class RescheduleAppointmentParams extends Equatable {
  final String appointmentId;
  final DateTime newDate;
  final String newTime;
  final String? reason;

  const RescheduleAppointmentParams({
    required this.appointmentId,
    required this.newDate,
    required this.newTime,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, newDate, newTime, reason];
}
