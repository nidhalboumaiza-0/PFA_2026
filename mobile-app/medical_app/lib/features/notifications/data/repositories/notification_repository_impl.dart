import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    String? type,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final notifications = await remoteDataSource.getNotifications(
          page: page,
          limit: limit,
          unreadOnly: unreadOnly,
          type: type,
        );
        return Right(notifications);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationsCount() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadNotificationsCount();
        return Right(count);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> markNotificationAsRead(
    String notificationId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markNotificationAsRead(notificationId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllNotificationsAsRead() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllNotificationsAsRead();
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> getNotificationPreferences() async {
    if (await networkInfo.isConnected) {
      try {
        final preferences = await remoteDataSource.getNotificationPreferences();
        return Right(preferences);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateNotificationPreferences(preferences);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDevice({
    required String playerId,
    required String platform,
    String? deviceModel,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.registerDevice(
          playerId: playerId,
          platform: platform,
          deviceModel: deviceModel,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> unregisterDevice(String playerId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unregisterDevice(playerId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNotification(
    String notificationId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotification(notificationId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  // OneSignal methods
  @override
  Future<Either<Failure, Unit>> initializeOneSignal() async {
    try {
      await remoteDataSource.initializeOneSignal();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setExternalUserId(String userId) async {
    try {
      await remoteDataSource.setExternalUserId(userId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getOneSignalPlayerId() async {
    try {
      final playerId = await remoteDataSource.getOneSignalPlayerId();
      return Right(playerId);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveOneSignalPlayerId(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveOneSignalPlayerId(userId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Legacy method for backwards compatibility
  @override
  Future<Either<Failure, Unit>> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    Map<String, dynamic>? data,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendNotification(
          title: title,
          body: body,
          senderId: senderId,
          recipientId: recipientId,
          type: type,
          appointmentId: appointmentId,
          prescriptionId: prescriptionId,
          data: data,
        );
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
