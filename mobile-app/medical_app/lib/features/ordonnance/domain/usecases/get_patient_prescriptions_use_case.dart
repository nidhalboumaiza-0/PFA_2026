import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';

class GetPatientPrescriptionsUseCase {
  final PrescriptionRepository repository;

  GetPatientPrescriptionsUseCase(this.repository);

  Future<Either<Failure, List<PrescriptionEntity>>> call({
    required String patientId,
  }) async {
    return await repository.getPatientPrescriptions(patientId);
  }
} 