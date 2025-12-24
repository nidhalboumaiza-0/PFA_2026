import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for sending a text message via Socket.IO
class SendMessage implements UseCase<bool, SendMessageParams> {
  final ConversationRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendMessageParams params) {
    return repository.sendMessage(
      conversationId: params.conversationId,
      receiverId: params.receiverId,
      content: params.content,
      messageType: params.messageType,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String receiverId;
  final String content;
  final String messageType;

  const SendMessageParams({
    required this.conversationId,
    required this.receiverId,
    required this.content,
    this.messageType = 'text',
  });

  @override
  List<Object?> get props => [
        conversationId,
        receiverId,
        content,
        messageType,
      ];
}

/// Use case for sending a file message via HTTP
class SendFileMessage implements UseCase<MessageEntity, SendFileMessageParams> {
  final ConversationRepository repository;

  SendFileMessage(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendFileMessageParams params) {
    return repository.sendFileMessage(
      conversationId: params.conversationId,
      filePath: params.filePath,
      messageType: params.messageType,
    );
  }
}

class SendFileMessageParams extends Equatable {
  final String conversationId;
  final String filePath;
  final String? messageType;

  const SendFileMessageParams({
    required this.conversationId,
    required this.filePath,
    this.messageType,
  });

  @override
  List<Object?> get props => [conversationId, filePath, messageType];
}
