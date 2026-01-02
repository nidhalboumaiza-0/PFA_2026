import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/messaging_repository.dart';

/// Use case to get user's conversations list
class GetConversationsUseCase
    implements UseCase<List<ConversationEntity>, GetConversationsParams> {
  final MessagingRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(
      GetConversationsParams params) {
    return repository.getConversations(
      type: params.type,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Parameters for GetConversationsUseCase
class GetConversationsParams extends Equatable {
  final String? type;
  final int page;
  final int limit;

  const GetConversationsParams({
    this.type,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [type, page, limit];
}
