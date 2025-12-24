import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';

class GetPrescriptionByAppointmentIdUseCase {
  final PrescriptionRepository repository;

  GetPrescriptionByAppointmentIdUseCase(this.repository);

  Future<Either<Failure, PrescriptionEntity?>> call({
    required String appointmentId,
  }) async {
    return await repository.getPrescriptionByAppointmentId(appointmentId);
  }
} 