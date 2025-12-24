import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class CancelAppointmentUseCase {
  final RendezVousRepository repository;

  CancelAppointmentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String appointmentId) async {
    return await repository.cancelAppointment(appointmentId);
  }
}
