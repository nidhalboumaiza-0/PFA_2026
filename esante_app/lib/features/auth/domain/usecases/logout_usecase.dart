import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, LogoutParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LogoutParams params) {
    return repository.logout(sessionId: params.sessionId);
  }
}

class LogoutParams extends Equatable {
  final String sessionId;

  const LogoutParams({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
