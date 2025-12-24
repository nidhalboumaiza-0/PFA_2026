import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class AcceptAppointmentUseCase {
  final RendezVousRepository repository;

  AcceptAppointmentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String appointmentId) async {
    return await repository.acceptAppointment(appointmentId);
  }
}
