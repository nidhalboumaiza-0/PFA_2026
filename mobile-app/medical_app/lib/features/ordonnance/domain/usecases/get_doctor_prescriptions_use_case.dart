import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';

class GetDoctorPrescriptionsUseCase {
  final PrescriptionRepository repository;

  GetDoctorPrescriptionsUseCase(this.repository);

  Future<Either<Failure, List<PrescriptionEntity>>> call({
    required String doctorId,
  }) async {
    return await repository.getDoctorPrescriptions(doctorId);
  }
} 