import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

class MarkMessagesAsRead implements UseCase<bool, MarkMessagesAsReadParams> {
  final ConversationRepository repository;

  MarkMessagesAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(MarkMessagesAsReadParams params) {
    return repository.markMessagesAsRead(params.conversationId);
  }
}

class MarkMessagesAsReadParams extends Equatable {
  final String conversationId;

  const MarkMessagesAsReadParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
