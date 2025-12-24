part of 'message_bloc.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

class InitializeMessageBloc extends MessageEvent {}

class FetchMessagesEvent extends MessageEvent {
  final String conversationId;
  final int page;
  final int limit;
  final bool forceReload;

  const FetchMessagesEvent({
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
    this.forceReload = false,
  });

  @override
  List<Object> get props => [conversationId, page, limit, forceReload];
}

class SendMessageEvent extends MessageEvent {
  final String conversationId;
  final String receiverId;
  final String content;
  final String type;
  final File? file;

  const SendMessageEvent({
    required this.conversationId,
    required this.receiverId,
    required this.content,
    required this.type,
    this.file,
  });

  @override
  List<Object?> get props => [conversationId, receiverId, content, type, file];
}

class MarkMessagesAsReadEvent extends MessageEvent {
  final String conversationId;

  const MarkMessagesAsReadEvent({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class MessageReceivedEvent extends MessageEvent {
  final MessageEntity message;

  const MessageReceivedEvent({required this.message});

  @override
  List<Object> get props => [message];
}

class SendTypingEvent extends MessageEvent {
  final String recipientId;
  final String conversationId;
  final bool isTyping;

  const SendTypingEvent({
    required this.recipientId,
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [recipientId, conversationId, isTyping];
}

class TypingIndicatorEvent extends MessageEvent {
  final bool isTyping;
  final String userId;

  const TypingIndicatorEvent({required this.isTyping, required this.userId});

  @override
  List<Object> get props => [isTyping, userId];
}
