import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';

class GetDoctorAppointmentsForDayUseCase {
  final RendezVousRepository repository;

  GetDoctorAppointmentsForDayUseCase(this.repository);

  Future<Either<Failure, List<RendezVousEntity>>> call({
    required String doctorId,
    required DateTime date,
  }) async {
    return await repository.getDoctorAppointmentsForDay(doctorId, date);
  }
}
