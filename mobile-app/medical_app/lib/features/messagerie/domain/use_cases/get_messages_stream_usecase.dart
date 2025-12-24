import 'package:equatable/equatable.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class GetMessagesStreamUseCase {
  final MessagingRepository repository;

  GetMessagesStreamUseCase(this.repository);

  Stream<List<MessageEntity>> call(GetMessagesStreamParams params) {
    return repository.getMessagesStream(params.conversationId);
  }
}

class GetMessagesStreamParams extends Equatable {
  final String conversationId;

  const GetMessagesStreamParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
