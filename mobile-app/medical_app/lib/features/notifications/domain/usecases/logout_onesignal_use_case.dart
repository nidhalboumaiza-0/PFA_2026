import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class LogoutOneSignalUseCase implements UseCase<Unit, NoParams> {
  final NotificationRepository repository;

  LogoutOneSignalUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.logout();
  }
}
