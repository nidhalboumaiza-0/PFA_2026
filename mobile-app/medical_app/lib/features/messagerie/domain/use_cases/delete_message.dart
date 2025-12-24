import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for deleting a message (soft delete)
class DeleteMessage implements UseCase<bool, DeleteMessageParams> {
  final ConversationRepository repository;

  DeleteMessage(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteMessageParams params) {
    return repository.deleteMessage(params.messageId);
  }
}

class DeleteMessageParams extends Equatable {
  final String messageId;

  const DeleteMessageParams({required this.messageId});

  @override
  List<Object> get props => [messageId];
}
