import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medical_history_entity.dart';
import '../repositories/medical_records_repository.dart';

/// Use case to get a patient's medical history (for doctors)
class GetPatientMedicalHistoryUseCase
    implements UseCase<MedicalHistoryEntity, GetPatientMedicalHistoryParams> {
  final MedicalRecordsRepository repository;

  GetPatientMedicalHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, MedicalHistoryEntity>> call(
      GetPatientMedicalHistoryParams params) {
    return repository.getPatientMedicalHistory(patientId: params.patientId);
  }
}

class GetPatientMedicalHistoryParams {
  final String patientId;

  const GetPatientMedicalHistoryParams({required this.patientId});
}
