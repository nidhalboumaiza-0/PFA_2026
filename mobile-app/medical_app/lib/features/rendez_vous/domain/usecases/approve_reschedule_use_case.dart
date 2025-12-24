import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

/// Use case for doctor to approve a patient's reschedule request
class ApproveRescheduleUseCase {
  final RendezVousRepository repository;

  ApproveRescheduleUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String appointmentId) async {
    return await repository.approveReschedule(appointmentId);
  }
}
