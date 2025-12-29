import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class CancelAppointmentUseCase
    implements UseCase<AppointmentEntity, CancelAppointmentParams> {
  final AppointmentRepository repository;

  CancelAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      CancelAppointmentParams params) {
    return repository.cancelAppointment(
      appointmentId: params.appointmentId,
      reason: params.reason,
    );
  }
}

class CancelAppointmentParams extends Equatable {
  final String appointmentId;
  final String reason;

  const CancelAppointmentParams({
    required this.appointmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}
