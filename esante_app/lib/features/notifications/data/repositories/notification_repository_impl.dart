import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  void _log(String method, String message) {
    print('[NotificationRepositoryImpl.$method] $message');
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    _log('getNotifications', 'Fetching notifications page=$page');

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final notifications = await remoteDataSource.getNotifications(
        page: page,
        limit: limit,
        unreadOnly: unreadOnly,
      );
      _log('getNotifications', 'Fetched ${notifications.length} notifications');
      return Right(notifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } catch (e) {
      _log('getNotifications', 'Error: $e');
      return Left(ServerFailure(code: 'UNKNOWN', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markAsRead(
      String notificationId) async {
    _log('markAsRead', 'Marking notification $notificationId as read');

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final notification = await remoteDataSource.markAsRead(notificationId);
      return Right(notification);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } catch (e) {
      return Left(ServerFailure(code: 'UNKNOWN', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    _log('markAllAsRead', 'Marking all notifications as read');

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.markAllAsRead();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } catch (e) {
      return Left(ServerFailure(code: 'UNKNOWN', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    _log('getUnreadCount', 'Fetching unread count');

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final count = await remoteDataSource.getUnreadCount();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } catch (e) {
      return Left(ServerFailure(code: 'UNKNOWN', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    _log('deleteNotification', 'Deleting notification $notificationId');

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } catch (e) {
      return Left(ServerFailure(code: 'UNKNOWN', message: e.toString()));
    }
  }
}
