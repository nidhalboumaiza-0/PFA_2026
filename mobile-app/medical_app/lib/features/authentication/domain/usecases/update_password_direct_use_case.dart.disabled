import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class UpdatePasswordDirectUseCase {
  final AuthRepository repository;

  UpdatePasswordDirectUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await repository.updatePasswordDirect(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
