part of 'conversation_bloc.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationsLoaded extends ConversationState {
  final List<ConversationEntity> conversations;

  const ConversationsLoaded({required this.conversations});

  @override
  List<Object> get props => [conversations];
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError({required this.message});

  @override
  List<Object> get props => [message];
}
