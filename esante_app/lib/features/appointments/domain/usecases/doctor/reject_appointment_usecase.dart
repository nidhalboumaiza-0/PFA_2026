import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class RejectAppointmentUseCase
    implements UseCase<AppointmentEntity, RejectAppointmentParams> {
  final AppointmentRepository repository;

  RejectAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      RejectAppointmentParams params) {
    return repository.rejectAppointment(
      appointmentId: params.appointmentId,
      reason: params.reason,
    );
  }
}

class RejectAppointmentParams extends Equatable {
  final String appointmentId;
  final String reason;

  const RejectAppointmentParams({
    required this.appointmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}
