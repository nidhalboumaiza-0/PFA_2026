import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/message_repository.dart';

/// Use case for getting conversations using MessagingRepository
class GetConversationsUseCase
    implements UseCase<List<ConversationEntity>, NoParams> {
  final MessagingRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConversationEntity>>> call(NoParams params) {
    return repository.getConversations();
  }
}
