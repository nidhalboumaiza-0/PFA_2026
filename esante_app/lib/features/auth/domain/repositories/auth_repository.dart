import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_tokens_entity.dart';
import '../entities/session_entity.dart';

abstract class AuthRepository {
  /// Register a new user
  Future<Either<Failure, String>> register({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  });

  /// Login with email and password
  Future<Either<Failure, (UserEntity, AuthTokensEntity)>> login({
    required String email,
    required String password,
  });

  /// Logout current session
  Future<Either<Failure, void>> logout({required String sessionId});

  /// Logout from all devices
  Future<Either<Failure, int>> logoutAllDevices();

  /// Refresh access token
  Future<Either<Failure, String>> refreshToken({required String refreshToken});

  /// Get current user info
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Verify email with token
  Future<Either<Failure, void>> verifyEmail({required String token});

  /// Resend verification email
  Future<Either<Failure, void>> resendVerification({required String email});

  /// Request password reset
  Future<Either<Failure, void>> forgotPassword({required String email});

  /// Reset password with token
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Change password (authenticated)
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Get all active sessions
  Future<Either<Failure, List<SessionEntity>>> getActiveSessions();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get cached tokens
  Future<AuthTokensEntity?> getCachedTokens();

  /// Get cached user
  Future<UserEntity?> getCachedUser();

  /// Restore session for returning user (initializes WebSocket)
  Future<void> restoreSession();
}
