import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for searching messages
class SearchMessages implements UseCase<List<MessageEntity>, SearchMessagesParams> {
  final ConversationRepository repository;

  SearchMessages(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(SearchMessagesParams params) {
    return repository.searchMessages(
      query: params.query,
      conversationId: params.conversationId,
      page: params.page,
      limit: params.limit,
    );
  }
}

class SearchMessagesParams extends Equatable {
  final String query;
  final String? conversationId;
  final int? page;
  final int? limit;

  const SearchMessagesParams({
    required this.query,
    this.conversationId,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [query, conversationId, page, limit];
}
