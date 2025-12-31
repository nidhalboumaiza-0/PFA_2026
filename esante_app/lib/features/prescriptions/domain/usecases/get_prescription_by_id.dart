import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prescription_entity.dart';
import '../repositories/prescription_repository.dart';

/// Use case to get prescription by ID
class GetPrescriptionByIdUseCase
    implements UseCase<PrescriptionEntity, String> {
  final PrescriptionRepository repository;

  GetPrescriptionByIdUseCase(this.repository);

  @override
  Future<Either<Failure, PrescriptionEntity>> call(String prescriptionId) {
    return repository.getPrescriptionById(prescriptionId);
  }
}
