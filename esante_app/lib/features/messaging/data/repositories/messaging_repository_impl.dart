import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';

/// Implementation of MessagingRepository
class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource remoteDataSource;

  MessagingRepositoryImpl({required this.remoteDataSource});

  void _log(String method, String message) {
    print('[MessagingRepository.$method] $message');
  }

  Failure _mapExceptionToFailure(dynamic e) {
    _log('_mapExceptionToFailure', 'Mapping exception: $e');
    if (e is ServerException) {
      return ServerFailure(code: e.code ?? 'SERVER_ERROR', message: e.message);
    } else if (e is NetworkException) {
      return NetworkFailure(message: e.message);
    } else if (e is UnauthorizedException) {
      return AuthFailure(message: e.message);
    }
    return ServerFailure(code: 'UNKNOWN', message: e.toString());
  }

  @override
  Future<Either<Failure, ConversationEntity>> createOrGetConversation({
    required String recipientId,
    required String recipientType,
  }) async {
    try {
      _log('createOrGetConversation', 'Creating/getting conversation with $recipientId');
      final conversation = await remoteDataSource.createOrGetConversation(
        recipientId: recipientId,
        recipientType: recipientType,
      );
      return Right(conversation.toEntity());
    } catch (e) {
      _log('createOrGetConversation', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _log('getConversations', 'Fetching conversations (page: $page)');
      final conversations = await remoteDataSource.getConversations(
        type: type,
        page: page,
        limit: limit,
      );
      return Right(conversations.map((c) => c.toEntity()).toList());
    } catch (e) {
      _log('getConversations', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? before,
  }) async {
    try {
      _log('getConversationMessages', 'Fetching messages for $conversationId');
      final messages = await remoteDataSource.getConversationMessages(
        conversationId: conversationId,
        page: page,
        limit: limit,
        before: before,
      );
      return Right(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      _log('getConversationMessages', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead({
    required String conversationId,
  }) async {
    try {
      _log('markMessagesAsRead', 'Marking messages as read for $conversationId');
      await remoteDataSource.markMessagesAsRead(conversationId: conversationId);
      return const Right(null);
    } catch (e) {
      _log('markMessagesAsRead', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendFileMessage({
    required String conversationId,
    required File file,
    String? caption,
  }) async {
    try {
      _log('sendFileMessage', 'Sending file message to $conversationId');
      final message = await remoteDataSource.sendFileMessage(
        conversationId: conversationId,
        file: file,
        caption: caption,
      );
      return Right(message.toEntity());
    } catch (e) {
      _log('sendFileMessage', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
  }) async {
    try {
      _log('deleteMessage', 'Deleting message $messageId');
      await remoteDataSource.deleteMessage(messageId: messageId);
      return const Right(null);
    } catch (e) {
      _log('deleteMessage', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      _log('getUnreadCount', 'Fetching unread count');
      final count = await remoteDataSource.getUnreadCount();
      return Right(count);
    } catch (e) {
      _log('getUnreadCount', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _log('searchMessages', 'Searching messages for "$query"');
      final messages = await remoteDataSource.searchMessages(
        query: query,
        conversationId: conversationId,
        page: page,
        limit: limit,
      );
      return Right(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      _log('searchMessages', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> getUserOnlineStatus({
    required String userId,
  }) async {
    try {
      _log('getUserOnlineStatus', 'Checking online status for $userId');
      final isOnline = await remoteDataSource.getUserOnlineStatus(userId: userId);
      return Right(isOnline);
    } catch (e) {
      _log('getUserOnlineStatus', 'Error: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }
}
