import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class GetOneSignalPlayerIdUseCase implements UseCase<String?, NoParams> {
  final NotificationRepository repository;

  GetOneSignalPlayerIdUseCase(this.repository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    return await repository.getOneSignalPlayerId();
  }
}
