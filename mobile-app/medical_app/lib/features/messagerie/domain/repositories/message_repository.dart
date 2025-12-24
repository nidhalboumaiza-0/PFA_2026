import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';

/// Repository interface for messaging operations
/// This is a simplified interface that delegates to ConversationRepository
abstract class MessagingRepository {
  /// Get user's conversations list
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    int? page,
    int? limit,
    bool? archived,
  });

  /// Get conversation messages
  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String conversationId, {
    int? page,
    int? limit,
  });

  /// Send a text message via Socket.IO
  Future<Either<Failure, bool>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType,
  });

  /// Send a file message via HTTP
  Future<Either<Failure, MessageEntity>> sendFileMessage({
    required String conversationId,
    required String filePath,
    String? messageType,
  });

  /// Mark messages as read in a conversation
  Future<Either<Failure, bool>> markAsRead(String conversationId);

  /// Get unread message count
  Future<Either<Failure, int>> getUnreadCount();

  /// Delete a message
  Future<Either<Failure, bool>> deleteMessage(String messageId);

  /// Get a stream of messages for a specific conversation
  Stream<List<MessageEntity>> getMessagesStream(String conversationId);

  /// Stream of messages for real-time updates
  Stream<MessageEntity> get messageStream;

  /// Stream of typing indicators
  Stream<Map<String, dynamic>> get typingStream;
}
