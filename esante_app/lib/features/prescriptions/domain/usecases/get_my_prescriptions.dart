import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prescription_entity.dart';
import '../repositories/prescription_repository.dart';

/// Parameters for GetMyPrescriptions use case
class GetMyPrescriptionsParams {
  final String? status;
  final int page;
  final int limit;

  const GetMyPrescriptionsParams({
    this.status,
    this.page = 1,
    this.limit = 20,
  });
}

/// Use case to get patient's prescriptions
class GetMyPrescriptionsUseCase
    implements UseCase<List<PrescriptionEntity>, GetMyPrescriptionsParams> {
  final PrescriptionRepository repository;

  GetMyPrescriptionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> call(
    GetMyPrescriptionsParams params,
  ) {
    return repository.getMyPrescriptions(
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}
