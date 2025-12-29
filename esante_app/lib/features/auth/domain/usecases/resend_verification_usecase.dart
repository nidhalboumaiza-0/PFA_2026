import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationUseCase implements UseCase<void, ResendVerificationParams> {
  final AuthRepository repository;

  ResendVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResendVerificationParams params) {
    return repository.resendVerification(email: params.email);
  }
}

class ResendVerificationParams extends Equatable {
  final String email;

  const ResendVerificationParams({required this.email});

  @override
  List<Object?> get props => [email];
}
