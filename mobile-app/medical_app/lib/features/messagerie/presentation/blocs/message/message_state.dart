part of 'message_bloc.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {
  const MessageInitial();
}

class MessageLoading extends MessageState {
  final bool isInitialLoad;
  final List<MessageEntity>? messages;

  const MessageLoading({required this.isInitialLoad, this.messages});

  @override
  List<Object?> get props => [isInitialLoad, messages];
}

class MessageLoaded extends MessageState {
  final List<MessageEntity> messages;
  final bool isTyping;
  final String? errorMessage;

  const MessageLoaded({
    required this.messages,
    this.isTyping = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [messages, isTyping, errorMessage];
}

class MessageError extends MessageState {
  final String message;

  const MessageError({required this.message});

  @override
  List<Object> get props => [message];
}
