part of 'conversation_bloc.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeConversationBloc extends ConversationEvent {}

class FetchConversationsEvent extends ConversationEvent {
  final int? page;
  final int? limit;
  final bool? archived;

  const FetchConversationsEvent({
    this.page,
    this.limit,
    this.archived,
  });

  @override
  List<Object?> get props => [page, limit, archived];
}

class UpdateConversationsEvent extends ConversationEvent {
  final List<ConversationEntity> conversations;

  const UpdateConversationsEvent({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class CreateConversationEvent extends ConversationEvent {
  final String participantId;
  final String participantType; // 'patient' or 'doctor'

  const CreateConversationEvent({
    required this.participantId,
    required this.participantType,
  });

  @override
  List<Object?> get props => [participantId, participantType];
}
