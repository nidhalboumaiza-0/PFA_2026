import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for getting conversation messages history
class GetMessages implements UseCase<List<MessageEntity>, GetMessagesParams> {
  final ConversationRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(GetMessagesParams params) {
    return repository.getConversationMessages(
      params.conversationId,
      page: params.page,
      limit: params.limit,
      before: params.before,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final int? page;
  final int? limit;
  final DateTime? before;

  const GetMessagesParams({
    required this.conversationId,
    this.page,
    this.limit,
    this.before,
  });

  @override
  List<Object?> get props => [conversationId, page, limit, before];
}
