import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Base class for messaging states
abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

/// Loading conversations
class ConversationsLoading extends MessagingState {
  const ConversationsLoading();
}

/// Conversations loaded successfully
class ConversationsLoaded extends MessagingState {
  final List<ConversationEntity> conversations;
  final bool hasMore;
  final int currentPage;
  final DateTime? lastUpdated; // Force state change detection

  const ConversationsLoaded({
    required this.conversations,
    this.hasMore = true,
    this.currentPage = 1,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [conversations, hasMore, currentPage, lastUpdated];

  ConversationsLoaded copyWith({
    List<ConversationEntity>? conversations,
    bool? hasMore,
    int? currentPage,
    DateTime? lastUpdated,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Error loading conversations
class ConversationsError extends MessagingState {
  final String message;

  const ConversationsError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading messages for a conversation
class MessagesLoading extends MessagingState {
  final String conversationId;

  const MessagesLoading({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

/// Messages loaded successfully
class MessagesLoaded extends MessagingState {
  final String conversationId;
  final ConversationEntity? conversation;
  final List<MessageEntity> messages;
  final bool hasMore;
  final int currentPage;
  final bool isTyping;
  final String? typingUserId;

  const MessagesLoaded({
    required this.conversationId,
    this.conversation,
    required this.messages,
    this.hasMore = true,
    this.currentPage = 1,
    this.isTyping = false,
    this.typingUserId,
  });

  @override
  List<Object?> get props => [
        conversationId,
        conversation,
        messages,
        hasMore,
        currentPage,
        isTyping,
        typingUserId,
      ];

  MessagesLoaded copyWith({
    String? conversationId,
    ConversationEntity? conversation,
    List<MessageEntity>? messages,
    bool? hasMore,
    int? currentPage,
    bool? isTyping,
    String? typingUserId,
  }) {
    return MessagesLoaded(
      conversationId: conversationId ?? this.conversationId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
    );
  }
}

/// Error loading messages
class MessagesError extends MessagingState {
  final String conversationId;
  final String message;

  const MessagesError({
    required this.conversationId,
    required this.message,
  });

  @override
  List<Object?> get props => [conversationId, message];
}

/// Sending a message
class MessageSending extends MessagingState {
  final String conversationId;
  final String tempId;

  const MessageSending({
    required this.conversationId,
    required this.tempId,
  });

  @override
  List<Object?> get props => [conversationId, tempId];
}

/// Message sent successfully
class MessageSent extends MessagingState {
  final MessageEntity message;
  final String? tempId;

  const MessageSent({
    required this.message,
    this.tempId,
  });

  @override
  List<Object?> get props => [message, tempId];
}

/// Error sending message
class MessageSendError extends MessagingState {
  final String conversationId;
  final String message;
  final String? tempId;

  const MessageSendError({
    required this.conversationId,
    required this.message,
    this.tempId,
  });

  @override
  List<Object?> get props => [conversationId, message, tempId];
}

/// Conversation created/retrieved
class ConversationCreated extends MessagingState {
  final ConversationEntity conversation;

  const ConversationCreated({required this.conversation});

  @override
  List<Object?> get props => [conversation];
}

/// Error creating conversation
class ConversationError extends MessagingState {
  final String message;

  const ConversationError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Unread count loaded
class UnreadCountLoaded extends MessagingState {
  final int count;

  const UnreadCountLoaded({required this.count});

  @override
  List<Object?> get props => [count];
}

/// Search results
class SearchResultsLoaded extends MessagingState {
  final String query;
  final List<MessageEntity> results;

  const SearchResultsLoaded({
    required this.query,
    required this.results,
  });

  @override
  List<Object?> get props => [query, results];
}

/// Search in progress
class SearchLoading extends MessagingState {
  final String query;

  const SearchLoading({required this.query});

  @override
  List<Object?> get props => [query];
}
