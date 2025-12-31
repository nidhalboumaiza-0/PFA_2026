import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/prescription_entity.dart';
import '../usecases/create_prescription.dart';

/// Repository interface for prescription operations
abstract class PrescriptionRepository {
  /// Get patient's prescriptions
  Future<Either<Failure, List<PrescriptionEntity>>> getMyPrescriptions({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get prescription by ID
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(
    String prescriptionId,
  );

  /// Create a new prescription (Doctor only)
  Future<Either<Failure, PrescriptionEntity>> createPrescription(
    CreatePrescriptionParams params,
  );
}
