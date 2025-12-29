import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

class CompleteAppointmentUseCase
    implements UseCase<AppointmentEntity, CompleteAppointmentParams> {
  final AppointmentRepository repository;

  CompleteAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      CompleteAppointmentParams params) {
    return repository.completeAppointment(
      appointmentId: params.appointmentId,
      notes: params.notes,
    );
  }
}

class CompleteAppointmentParams extends Equatable {
  final String appointmentId;
  final String? notes;

  const CompleteAppointmentParams({
    required this.appointmentId,
    this.notes,
  });

  @override
  List<Object?> get props => [appointmentId, notes];
}
