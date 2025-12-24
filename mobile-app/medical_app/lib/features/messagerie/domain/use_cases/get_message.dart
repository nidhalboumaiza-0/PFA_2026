import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

class GetMessagesUseCase
    implements UseCase<List<MessageEntity>, GetMessagesParams> {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(GetMessagesParams params) {
    return repository.getMessages(params.conversationId);
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;

  const GetMessagesParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
