import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

/// Use case to get messages for a conversation
class GetMessagesUseCase
    implements UseCase<List<MessageEntity>, GetMessagesParams> {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(GetMessagesParams params) {
    return repository.getConversationMessages(
      conversationId: params.conversationId,
      page: params.page,
      limit: params.limit,
      before: params.before,
    );
  }
}

/// Parameters for GetMessagesUseCase
class GetMessagesParams extends Equatable {
  final String conversationId;
  final int page;
  final int limit;
  final String? before;

  const GetMessagesParams({
    required this.conversationId,
    this.page = 1,
    this.limit = 50,
    this.before,
  });

  @override
  List<Object?> get props => [conversationId, page, limit, before];
}
