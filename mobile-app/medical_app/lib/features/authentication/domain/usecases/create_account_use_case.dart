import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

class CreateAccountUseCase {
  final AuthRepository authRepository;

  CreateAccountUseCase(this.authRepository);

  Future<Either<Failure, Unit>> call(UserEntity user, String password) async {
    return await authRepository.createAccount(user: user, password: password);
  }
}