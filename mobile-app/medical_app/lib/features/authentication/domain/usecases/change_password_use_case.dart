import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await repository.changePassword(
      currentPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}