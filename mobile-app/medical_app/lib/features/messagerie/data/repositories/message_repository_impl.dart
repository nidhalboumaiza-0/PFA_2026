import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/messagerie/data/data_sources/conversation_api_data_source.dart';
import 'package:medical_app/features/messagerie/data/data_sources/socket_service.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

/// Implementation of MessagingRepository that uses the conversation API and socket service
class MessagingRepositoryImpl implements MessagingRepository {
  final ConversationApiDataSource apiDataSource;
  final SocketService socketService;
  final NetworkInfo networkInfo;

  MessagingRepositoryImpl({
    required this.apiDataSource,
    required this.socketService,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    int? page,
    int? limit,
    bool? archived,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final conversations = await apiDataSource.getConversations(
          page: page,
          limit: limit,
          archived: archived,
        );
        return Right(conversations);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String conversationId, {
    int? page,
    int? limit,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final messages = await apiDataSource.getConversationMessages(
          conversationId,
          page: page,
          limit: limit,
        );
        return Right(messages);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      socketService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
      );
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendFileMessage({
    required String conversationId,
    required String filePath,
    String? messageType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await apiDataSource.sendFileMessage(
          conversationId: conversationId,
          filePath: filePath,
          messageType: messageType,
        );
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String conversationId) async {
    if (await networkInfo.isConnected) {
      try {
        await apiDataSource.markMessagesAsRead(conversationId);
        return const Right(true);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await apiDataSource.getUnreadCount();
        return Right(count);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMessage(String messageId) async {
    if (await networkInfo.isConnected) {
      try {
        await apiDataSource.deleteMessage(messageId);
        return const Right(true);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Stream<MessageEntity> get messageStream => socketService.messageStream;

  @override
  Stream<Map<String, dynamic>> get typingStream => socketService.typingStream;
  
  @override
  Stream<List<MessageEntity>> getMessagesStream(String conversationId) {
    // For now, we don't have real-time message streaming per conversation from the API
    // Return a stream that emits an empty list - implement real-time when available
    return Stream.value([]);
  }
}
