import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

/// Use case for doctor to reschedule an appointment directly
/// No patient approval is required
class RescheduleAppointmentUseCase {
  final RendezVousRepository repository;

  RescheduleAppointmentUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    return await repository.rescheduleAppointment(
      appointmentId,
      newDate: newDate,
      newTime: newTime,
      reason: reason,
    );
  }
}
