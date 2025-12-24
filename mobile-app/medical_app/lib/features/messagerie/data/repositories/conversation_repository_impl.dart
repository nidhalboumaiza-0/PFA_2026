import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/messagerie/data/data_sources/conversation_api_data_source.dart';
import 'package:medical_app/features/messagerie/data/data_sources/socket_service.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationApiDataSource apiDataSource;
  final SocketService socketService;
  final NetworkInfo networkInfo;

  ConversationRepositoryImpl({
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
  Future<Either<Failure, ConversationEntity>> createOrGetConversation({
    required String participantId,
    required String participantType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final conversation = await apiDataSource.createOrGetConversation(
          participantId: participantId,
          participantType: participantType,
        );
        return Right(conversation);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getConversationMessages(
    String conversationId, {
    int? page,
    int? limit,
    DateTime? before,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final messages = await apiDataSource.getConversationMessages(
          conversationId,
          page: page,
          limit: limit,
          before: before,
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
  Future<Either<Failure, bool>> markMessagesAsRead(
    String conversationId,
  ) async {
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
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    String? conversationId,
    int? page,
    int? limit,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final messages = await apiDataSource.searchMessages(
          query: query,
          conversationId: conversationId,
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
  Future<Either<Failure, bool>> getOnlineStatus(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final isOnline = await apiDataSource.getOnlineStatus(userId);
        return Right(isOnline);
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

  // Socket.IO related methods

  @override
  Future<Either<Failure, bool>> connectToSocket({bool forceReconnect = false}) async {
    try {
      await socketService.connect(forceReconnect: forceReconnect);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> disconnectFromSocket() async {
    try {
      socketService.disconnect();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<MessageEntity> get messageStream => socketService.messageStream;

  @override
  Stream<Map<String, dynamic>> get typingStream => socketService.typingStream;

  @override
  Stream<Map<String, dynamic>> get readReceiptStream =>
      socketService.readReceiptStream;

  @override
  Stream<Map<String, dynamic>> get onlineStatusStream =>
      socketService.onlineStatusStream;

  @override
  Stream<bool> get connectionStatusStream => socketService.connectionStatusStream;

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
  Future<Either<Failure, bool>> sendTypingIndicator({
    required String conversationId,
    required String recipientId,
    required bool isTyping,
  }) async {
    try {
      socketService.sendTypingIndicator(
        conversationId: conversationId,
        recipientId: recipientId,
        isTyping: isTyping,
      );
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> joinConversation(String conversationId) async {
    try {
      socketService.joinConversation(conversationId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> leaveConversation(String conversationId) async {
    try {
      socketService.leaveConversation(conversationId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
