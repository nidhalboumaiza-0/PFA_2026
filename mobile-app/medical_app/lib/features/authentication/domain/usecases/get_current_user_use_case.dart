import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

/// Use case to get the currently authenticated user
/// Used by messaging, socket service, and other features that need user info
class GetCurrentUser implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call([NoParams? params]) async {
    return repository.getCurrentUser();
  }
}
