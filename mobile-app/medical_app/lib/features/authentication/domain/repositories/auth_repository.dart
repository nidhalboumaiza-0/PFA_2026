import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  
  Future<Either<Failure, Unit>> createAccount({
    required UserEntity user,
    required String password,
  });
  
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, Unit>> logout();
  
  /// Get the currently authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser();
  
  Future<Either<Failure, Unit>> verifyEmailWithToken(String token);
  
  Future<Either<Failure, Unit>> resendVerification(String email);
  
  Future<Either<Failure, Unit>> forgotPassword(String email);
  
  Future<Either<Failure, Unit>> resetPasswordWithToken({
    required String token,
    required String newPassword,
  });
  
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  Future<Either<Failure, String>> refreshToken(String refreshToken);
  
  Future<Either<Failure, Unit>> updateUser(UserEntity user);
}
