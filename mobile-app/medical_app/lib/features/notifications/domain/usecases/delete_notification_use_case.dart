import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class DeleteNotificationUseCase
    implements UseCase<Unit, DeleteNotificationParams> {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteNotificationParams params) async {
    return await repository.deleteNotification(params.notificationId);
  }
}

class DeleteNotificationParams extends Equatable {
  final String notificationId;

  const DeleteNotificationParams({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}
