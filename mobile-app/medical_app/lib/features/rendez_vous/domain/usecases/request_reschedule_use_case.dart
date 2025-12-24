import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

/// Use case for patient to request a reschedule
/// Requires doctor approval
class RequestRescheduleUseCase {
  final RendezVousRepository repository;

  RequestRescheduleUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    return await repository.requestReschedule(
      appointmentId,
      newDate: newDate,
      newTime: newTime,
      reason: reason,
    );
  }
}
