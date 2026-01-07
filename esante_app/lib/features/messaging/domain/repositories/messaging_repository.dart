import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

/// Repository interface for messaging operations
abstract class MessagingRepository {
  /// Create or get existing conversation with a user
  Future<Either<Failure, ConversationEntity>> createOrGetConversation({
    required String recipientId,
    required String recipientType,
  });

  /// Get list of user's conversations
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    String? type,
    int page = 1,
    int limit = 20,
  });

  /// Get messages for a conversation
  Future<Either<Failure, List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? before,
  });

  /// Mark messages as read in a conversation
  Future<Either<Failure, void>> markMessagesAsRead({
    required String conversationId,
  });

  /// Send a file message
  Future<Either<Failure, MessageEntity>> sendFileMessage({
    required String conversationId,
    required String receiverId,
    required File file,
    String? caption,
  });

  /// Delete a message
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
  });

  /// Get unread message count
  Future<Either<Failure, int>> getUnreadCount();

  /// Search messages
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    String? conversationId,
    int page = 1,
    int limit = 20,
  });

  /// Get user's online status
  Future<Either<Failure, bool>> getUserOnlineStatus({
    required String userId,
  });
}
