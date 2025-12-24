import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase
    implements UseCase<Unit, MarkNotificationAsReadParams> {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    MarkNotificationAsReadParams params,
  ) async {
    return await repository.markNotificationAsRead(params.notificationId);
  }
}

class MarkNotificationAsReadParams extends Equatable {
  final String notificationId;

  const MarkNotificationAsReadParams({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}
