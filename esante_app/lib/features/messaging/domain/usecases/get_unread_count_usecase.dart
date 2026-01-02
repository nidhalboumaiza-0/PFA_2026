import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/messaging_repository.dart';

/// Use case to get unread message count
class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  final MessagingRepository repository;

  GetUnreadCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return repository.getUnreadCount();
  }
}
