import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ordonnance/domain/repositories/prescription_repository.dart';

class UpdatePrescriptionStatusUseCase {
  final PrescriptionRepository repository;

  UpdatePrescriptionStatusUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String prescriptionId,
    required String status,
  }) async {
    return await repository.updatePrescriptionStatus(prescriptionId, status);
  }
}
