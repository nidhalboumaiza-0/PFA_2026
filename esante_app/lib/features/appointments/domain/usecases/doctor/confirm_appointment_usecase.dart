import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class ConfirmAppointmentUseCase
    implements UseCase<AppointmentEntity, ConfirmAppointmentParams> {
  final AppointmentRepository repository;

  ConfirmAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      ConfirmAppointmentParams params) {
    return repository.confirmAppointment(
      appointmentId: params.appointmentId,
    );
  }
}

class ConfirmAppointmentParams extends Equatable {
  final String appointmentId;

  const ConfirmAppointmentParams({
    required this.appointmentId,
  });

  @override
  List<Object?> get props => [appointmentId];
}
