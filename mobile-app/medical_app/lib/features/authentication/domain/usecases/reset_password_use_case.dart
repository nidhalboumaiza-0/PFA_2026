import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String token,
    required String newPassword,
  }) async {
    return await repository.resetPasswordWithToken(
      token: token,
      newPassword: newPassword,
    );
  }
}
