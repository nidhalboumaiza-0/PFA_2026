import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

class GetConversations implements UseCase<List<ConversationEntity>, GetConversationsParams> {
  final ConversationRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(GetConversationsParams params) {
    return repository.getConversations(
      page: params.page,
      limit: params.limit,
      archived: params.archived,
    );
  }
}

class GetConversationsParams extends Equatable {
  final int? page;
  final int? limit;
  final bool? archived;

  const GetConversationsParams({
    this.page,
    this.limit,
    this.archived,
  });

  @override
  List<Object?> get props => [page, limit, archived];

  /// Convenience constructor for default params
  static const GetConversationsParams empty = GetConversationsParams();
}
