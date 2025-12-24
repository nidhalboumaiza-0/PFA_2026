import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';

class GetPrescriptionByIdUseCase {
  final PrescriptionRepository repository;

  GetPrescriptionByIdUseCase(this.repository);

  Future<Either<Failure, PrescriptionEntity>> call({
    required String prescriptionId,
  }) async {
    return await repository.getPrescriptionById(prescriptionId);
  }
} 