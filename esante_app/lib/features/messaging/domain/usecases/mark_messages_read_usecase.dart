import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/messaging_repository.dart';

/// Use case to mark messages as read in a conversation
class MarkMessagesReadUseCase
    implements UseCase<void, MarkMessagesReadParams> {
  final MessagingRepository repository;

  MarkMessagesReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkMessagesReadParams params) {
    return repository.markMessagesAsRead(
      conversationId: params.conversationId,
    );
  }
}

/// Parameters for MarkMessagesReadUseCase
class MarkMessagesReadParams extends Equatable {
  final String conversationId;

  const MarkMessagesReadParams({
    required this.conversationId,
  });

  @override
  List<Object?> get props => [conversationId];
}
