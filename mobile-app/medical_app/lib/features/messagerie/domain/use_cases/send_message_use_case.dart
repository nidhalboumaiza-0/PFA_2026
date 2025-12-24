import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class SendMessageUseCase implements UseCase<bool, SendMessageParams> {
  final MessagingRepository repository;

  SendMessageUseCase(this.repository);

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
  List<Object> get props => [conversationId, receiverId, content, messageType];
}
