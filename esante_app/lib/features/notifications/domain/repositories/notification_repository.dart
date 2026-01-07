import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  });

  Future<Either<Failure, NotificationEntity>> markAsRead(String notificationId);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> deleteNotification(String notificationId);
}
