import 'dart:io';
import 'package:equatable/equatable.dart';

/// Base class for messaging events
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

// ============== Conversation Events ==============

/// Load conversations list
class LoadConversations extends MessagingEvent {
  final String? type;
  final int page;
  final bool refresh;
  final bool forceEmit; // Force emit ConversationsLoaded even if in MessagesLoaded state

  const LoadConversations({
    this.type,
    this.page = 1,
    this.refresh = false,
    this.forceEmit = false,
  });

  @override
  List<Object?> get props => [type, page, refresh, forceEmit];
}

/// Create or get a conversation with a user
class CreateConversation extends MessagingEvent {
  final String recipientId;
  final String recipientType;

  const CreateConversation({
    required this.recipientId,
    required this.recipientType,
  });

  @override
  List<Object?> get props => [recipientId, recipientType];
}

/// Select a conversation to view
class SelectConversation extends MessagingEvent {
  final String conversationId;

  const SelectConversation({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

// ============== Message Events ==============

/// Load messages for a conversation
class LoadMessages extends MessagingEvent {
  final String conversationId;
  final int page;
  final bool refresh;

  const LoadMessages({
    required this.conversationId,
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [conversationId, page, refresh];
}

/// Load more messages (pagination)
class LoadMoreMessages extends MessagingEvent {
  final String conversationId;
  final String? beforeMessageId;

  const LoadMoreMessages({
    required this.conversationId,
    this.beforeMessageId,
  });

  @override
  List<Object?> get props => [conversationId, beforeMessageId];
}

/// Send a text message (via socket - handled separately)
class SendTextMessage extends MessagingEvent {
  final String conversationId;
  final String receiverId;
  final String content;
  final String? tempId;

  const SendTextMessage({
    required this.conversationId,
    required this.receiverId,
    required this.content,
    this.tempId,
  });

  @override
  List<Object?> get props => [conversationId, receiverId, content, tempId];
}

/// Send a file message
class SendFileMessage extends MessagingEvent {
  final String conversationId;
  final String receiverId;
  final File file;
  final String? caption;

  const SendFileMessage({
    required this.conversationId,
    required this.receiverId,
    required this.file,
    this.caption,
  });

  @override
  List<Object?> get props => [conversationId, receiverId, file.path, caption];
}

/// Mark messages as read
class MarkMessagesRead extends MessagingEvent {
  final String conversationId;

  const MarkMessagesRead({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

/// Delete a message
class DeleteMessage extends MessagingEvent {
  final String messageId;

  const DeleteMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

// ============== Socket Events ==============

/// Message received from socket
class MessageReceived extends MessagingEvent {
  final Map<String, dynamic> messageData;

  const MessageReceived({required this.messageData});

  @override
  List<Object?> get props => [messageData];
}

/// Message sent confirmation from socket
class MessageSentConfirmation extends MessagingEvent {
  final String tempId;
  final Map<String, dynamic> messageData;

  const MessageSentConfirmation({
    required this.tempId,
    required this.messageData,
  });

  @override
  List<Object?> get props => [tempId, messageData];
}

/// User came online
class UserOnline extends MessagingEvent {
  final String userId;

  const UserOnline({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// User went offline
class UserOffline extends MessagingEvent {
  final String userId;

  const UserOffline({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Typing indicator received
class TypingIndicatorReceived extends MessagingEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const TypingIndicatorReceived({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

/// Start typing event (emit to socket)
class StartTyping extends MessagingEvent {
  final String conversationId;
  final String receiverId;

  const StartTyping({
    required this.conversationId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [conversationId, receiverId];
}

/// Stop typing event (emit to socket)
class StopTyping extends MessagingEvent {
  final String conversationId;
  final String receiverId;

  const StopTyping({
    required this.conversationId,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [conversationId, receiverId];
}

// ============== Unread Count Events ==============

/// Get unread message count
class GetUnreadCount extends MessagingEvent {
  const GetUnreadCount();
}

/// Update unread count (from socket notification)
class UpdateUnreadCount extends MessagingEvent {
  final int count;

  const UpdateUnreadCount({required this.count});

  @override
  List<Object?> get props => [count];
}

// ============== Search Events ==============

/// Search messages
class SearchMessages extends MessagingEvent {
  final String query;
  final String? conversationId;

  const SearchMessages({
    required this.query,
    this.conversationId,
  });

  @override
  List<Object?> get props => [query, conversationId];
}

/// Clear search results
class ClearSearch extends MessagingEvent {
  const ClearSearch();
}

// ============== UI Events ==============

/// Clear current conversation
class ClearCurrentConversation extends MessagingEvent {
  const ClearCurrentConversation();
}

/// Reset messaging state
class ResetMessaging extends MessagingEvent {
  const ResetMessaging();
}
