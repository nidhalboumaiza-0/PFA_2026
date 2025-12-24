import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

/// Use case for doctor to reject a patient's reschedule request
class RejectRescheduleUseCase {
  final RendezVousRepository repository;

  RejectRescheduleUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String appointmentId, {String? reason}) async {
    return await repository.rejectReschedule(appointmentId, reason: reason);
  }
}
