import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/conversation_entity.dart';
import '../repositories/messaging_repository.dart';

/// Use case to create or get an existing conversation
class CreateConversationUseCase
    implements UseCase<ConversationEntity, CreateConversationParams> {
  final MessagingRepository repository;

  CreateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(
      CreateConversationParams params) {
    return repository.createOrGetConversation(
      recipientId: params.recipientId,
      recipientType: params.recipientType,
    );
  }
}

/// Parameters for CreateConversationUseCase
class CreateConversationParams extends Equatable {
  final String recipientId;
  final String recipientType;

  const CreateConversationParams({
    required this.recipientId,
    required this.recipientType,
  });

  @override
  List<Object?> get props => [recipientId, recipientType];
}
