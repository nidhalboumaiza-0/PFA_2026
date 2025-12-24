import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class GetUnreadNotificationsCountUseCase implements UseCase<int, NoParams> {
  final NotificationRepository repository;

  GetUnreadNotificationsCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getUnreadNotificationsCount();
  }
}
