import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';

class CreatePrescriptionUseCase {
  final PrescriptionRepository repository;

  CreatePrescriptionUseCase(this.repository);

  Future<Either<Failure, PrescriptionEntity>> call({
    required PrescriptionEntity prescription,
  }) async {
    return await repository.createPrescription(prescription);
  }
} 