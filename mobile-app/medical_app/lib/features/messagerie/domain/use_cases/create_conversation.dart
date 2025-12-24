import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/entities/conversation_entity.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for creating or getting existing conversation
class CreateConversation implements UseCase<ConversationEntity, CreateConversationParams> {
  final ConversationRepository repository;

  CreateConversation(this.repository);

  @override
  Future<Either<Failure, ConversationEntity>> call(CreateConversationParams params) {
    return repository.createOrGetConversation(
      participantId: params.participantId,
      participantType: params.participantType,
    );
  }
}

class CreateConversationParams extends Equatable {
  final String participantId;
  final String participantType; // 'patient' or 'doctor'

  const CreateConversationParams({
    required this.participantId,
    required this.participantType,
  });

  @override
  List<Object> get props => [participantId, participantType];
}
