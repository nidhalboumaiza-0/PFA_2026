import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/medical_history_entity.dart';

/// Repository interface for medical records operations
abstract class MedicalRecordsRepository {
  /// Get patient's medical history (for doctors)
  /// 
  /// [patientId] - The ID of the patient whose history to fetch
  /// Returns [MedicalHistoryEntity] on success or [Failure] on error
  Future<Either<Failure, MedicalHistoryEntity>> getPatientMedicalHistory({
    required String patientId,
  });

  /// Get current user's own medical history (for patients)
  /// 
  /// Returns [MedicalHistoryEntity] on success or [Failure] on error
  Future<Either<Failure, MedicalHistoryEntity>> getMyMedicalHistory();
}
