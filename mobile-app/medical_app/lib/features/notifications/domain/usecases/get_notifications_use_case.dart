import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsParams extends Equatable {
  final int page;
  final int limit;
  final bool? unreadOnly;
  final String? type;

  const GetNotificationsParams({
    this.page = 1,
    this.limit = 20,
    this.unreadOnly,
    this.type,
  });

  @override
  List<Object?> get props => [page, limit, unreadOnly, type];
}

class GetNotificationsUseCase
    implements UseCase<List<NotificationEntity>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(
      page: params.page,
      limit: params.limit,
      unreadOnly: params.unreadOnly,
      type: params.type,
    );
  }
}
