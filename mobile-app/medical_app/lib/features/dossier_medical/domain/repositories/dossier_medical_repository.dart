import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../entities/dossier_medical_entity.dart';

abstract class DossierMedicalRepository {
  Future<Either<Failure, DossierMedicalEntity>> getDossierMedical(
    String patientId,
  );
  Future<Either<Failure, DossierMedicalEntity>> addFileToDossier(
    String patientId,
    String filePath,
    String description,
  );
  Future<Either<Failure, DossierMedicalEntity>> addFilesToDossier(
    String patientId,
    List<String> filePaths,
    Map<String, String> descriptions,
  );
  Future<Either<Failure, Unit>> deleteFile(String patientId, String fileId);
  Future<Either<Failure, Unit>> updateFileDescription(
    String patientId,
    String fileId,
    String description,
  );
  Future<Either<Failure, bool>> hasDossierMedical(String patientId);
}
