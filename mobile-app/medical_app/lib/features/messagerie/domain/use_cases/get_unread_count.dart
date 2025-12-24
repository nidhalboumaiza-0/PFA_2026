import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

/// Use case for getting unread message count
class GetUnreadCount implements UseCase<int, NoParams> {
  final ConversationRepository repository;

  GetUnreadCount(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return repository.getUnreadCount();
  }
}
