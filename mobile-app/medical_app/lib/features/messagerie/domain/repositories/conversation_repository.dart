import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';

abstract class ConversationRepository {
  /// Get user's conversations list
  /// GET /api/v1/messages/conversations
  Future<Either<Failure, List<ConversationEntity>>> getConversations({
    int? page,
    int? limit,
    bool? archived,
  });

  /// Create or get existing conversation
  /// POST /api/v1/messages/conversations
  Future<Either<Failure, ConversationEntity>> createOrGetConversation({
    required String participantId,
    required String participantType, // 'patient' or 'doctor'
  });

  /// Get conversation messages (history)
  /// GET /api/v1/messages/conversations/:conversationId/messages
  Future<Either<Failure, List<MessageEntity>>> getConversationMessages(
    String conversationId, {
    int? page,
    int? limit,
    DateTime? before,
  });

  /// Mark messages as read
  /// PUT /api/v1/messages/conversations/:conversationId/mark-read
  Future<Either<Failure, bool>> markMessagesAsRead(String conversationId);

  /// Send message with file attachment
  /// POST /api/v1/messages/conversations/:conversationId/send-file
  Future<Either<Failure, MessageEntity>> sendFileMessage({
    required String conversationId,
    required String filePath,
    String? messageType,
  });

  /// Get unread message count for user
  /// GET /api/v1/messages/unread-count
  Future<Either<Failure, int>> getUnreadCount();

  /// Search messages by content
  /// GET /api/v1/messages/search
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String query,
    String? conversationId,
    int? page,
    int? limit,
  });

  /// Check if user is online
  /// GET /api/v1/messages/users/:userId/online-status
  Future<Either<Failure, bool>> getOnlineStatus(String userId);

  /// Delete message (soft delete)
  /// DELETE /api/v1/messages/:messageId
  Future<Either<Failure, bool>> deleteMessage(String messageId);

  // Socket.IO related methods
  
  /// Connect to Socket.IO server
  /// If [forceReconnect] is true, will check actual connection status and reconnect if needed
  Future<Either<Failure, bool>> connectToSocket({bool forceReconnect = false});

  /// Disconnect from Socket.IO server
  Future<Either<Failure, bool>> disconnectFromSocket();

  /// Stream of incoming messages
  Stream<MessageEntity> get messageStream;

  /// Stream of typing indicators
  Stream<Map<String, dynamic>> get typingStream;

  /// Stream of read receipts
  Stream<Map<String, dynamic>> get readReceiptStream;

  /// Stream of online status updates
  Stream<Map<String, dynamic>> get onlineStatusStream;

  /// Stream of socket connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStatusStream;

  /// Send message via Socket.IO
  Future<Either<Failure, bool>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType,
  });

  /// Send typing indicator via Socket.IO
  Future<Either<Failure, bool>> sendTypingIndicator({
    required String conversationId,
    required String recipientId,
    required bool isTyping,
  });

  /// Join conversation room via Socket.IO
  Future<Either<Failure, bool>> joinConversation(String conversationId);

  /// Leave conversation room via Socket.IO
  Future<Either<Failure, bool>> leaveConversation(String conversationId);
}
