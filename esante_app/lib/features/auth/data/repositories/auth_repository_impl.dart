import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/websocket_service.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_tokens_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final WebSocketService _webSocketService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required WebSocketService webSocketService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _webSocketService = webSocketService;

  void _log(String method, String message) {
    print('[AuthRepository.$method] $message');
  }

  @override
  Future<Either<Failure, String>> register({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  }) async {
    return _handleRequest(() async {
      return await _remoteDataSource.register(
        email: email,
        password: password,
        role: role,
        profileData: profileData,
      );
    });
  }

  @override
  Future<Either<Failure, (UserEntity, AuthTokensEntity)>> login({
    required String email,
    required String password,
  }) async {
    _log('login', 'Starting login flow for: $email');
    return _handleRequest(() async {
      _log('login', 'Calling remote data source...');
      final (user, tokens) = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      _log('login', 'Remote login successful, user: ${user.email}');

      // Cache tokens and user locally
      _log('login', 'Caching tokens...');
      await _localDataSource.cacheTokens(tokens);
      _log('login', 'Caching user...');
      await _localDataSource.cacheUser(user);
      _log('login', 'All data cached');

      // Initialize WebSocket for real-time updates
      _log('login', 'Initializing WebSocket connection...');
      try {
        await _webSocketService.init(tokens.accessToken);
        _log('login', 'WebSocket initialized successfully');
      } catch (e) {
        // WebSocket failure shouldn't fail login
        _log('login', 'WebSocket init failed (non-blocking): $e');
      }

      _log('login', 'Returning success');
      return (user as UserEntity, tokens as AuthTokensEntity);
    });
  }

  @override
  Future<Either<Failure, void>> logout({required String sessionId}) async {
    return _handleRequest(() async {
      // Disconnect WebSocket first
      try {
        await _webSocketService.disconnect();
        _log('logout', 'WebSocket disconnected');
      } catch (e) {
        _log('logout', 'WebSocket disconnect failed (non-blocking): $e');
      }

      await _remoteDataSource.logout(sessionId: sessionId);
      await _localDataSource.clearAll();
    });
  }

  @override
  Future<Either<Failure, int>> logoutAllDevices() async {
    return _handleRequest(() async {
      // Disconnect WebSocket first
      try {
        await _webSocketService.disconnect();
        _log('logoutAllDevices', 'WebSocket disconnected');
      } catch (e) {
        _log('logoutAllDevices', 'WebSocket disconnect failed (non-blocking): $e');
      }

      final count = await _remoteDataSource.logoutAllDevices();
      await _localDataSource.clearAll();
      return count;
    });
  }

  @override
  Future<Either<Failure, String>> refreshToken({
    required String refreshToken,
  }) async {
    return _handleRequest(() async {
      final newAccessToken = await _remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      // Update cached tokens with new access token
      final currentTokens = await _localDataSource.getCachedTokens();
      if (currentTokens != null) {
        await _localDataSource.cacheTokens(
          AuthTokensModel(
            accessToken: newAccessToken,
            refreshToken: currentTokens.refreshToken,
            sessionId: currentTokens.sessionId,
          ),
        );
      }

      return newAccessToken;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    return _handleRequest(() async {
      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.cacheUser(user);
      return user;
    });
  }

  @override
  Future<Either<Failure, void>> verifyEmail({required String token}) async {
    return _handleRequest(() async {
      await _remoteDataSource.verifyEmail(token: token);
    });
  }

  @override
  Future<Either<Failure, void>> resendVerification({
    required String email,
  }) async {
    return _handleRequest(() async {
      await _remoteDataSource.resendVerification(email: email);
    });
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    return _handleRequest(() async {
      await _remoteDataSource.forgotPassword(email: email);
    });
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return _handleRequest(() async {
      await _remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
    });
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _handleRequest(() async {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getActiveSessions() async {
    return _handleRequest(() async {
      return await _remoteDataSource.getActiveSessions();
    });
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _localDataSource.hasTokens();
  }

  @override
  Future<AuthTokensEntity?> getCachedTokens() async {
    return await _localDataSource.getCachedTokens();
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    return await _localDataSource.getCachedUser();
  }

  @override
  Future<void> restoreSession() async {
    _log('restoreSession', 'Restoring session for returning user...');
    final tokens = await _localDataSource.getCachedTokens();
    if (tokens != null) {
      try {
        await _webSocketService.init(tokens.accessToken);
        _log('restoreSession', 'WebSocket initialized successfully');
      } catch (e) {
        _log('restoreSession', 'WebSocket init failed (non-blocking): $e');
      }
    } else {
      _log('restoreSession', 'No tokens found, skipping WebSocket init');
    }
  }

  /// Generic error handler for all repository methods
  Future<Either<Failure, T>> _handleRequest<T>(
    Future<T> Function() request,
  ) async {
    try {
      final result = await request();
      _log('_handleRequest', 'Request succeeded');
      return Right(result);
    } on ServerException catch (e) {
      _log('_handleRequest', 'ServerException: ${e.code} - ${e.message}');
      return Left(_mapServerExceptionToFailure(e));
    } on CacheException catch (e) {
      _log('_handleRequest', 'CacheException: ${e.message}');
      return Left(CacheFailure());
    } catch (e, stackTrace) {
      _log('_handleRequest', 'Unknown error: $e');
      _log('_handleRequest', 'StackTrace: $stackTrace');
      return Left(ServerFailure(
        code: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  Failure _mapServerExceptionToFailure(ServerException e) {
    // Special handling for email not verified
    if (e.isEmailNotVerified) {
      return AuthFailure(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }

    // Validation errors
    if (e.code == 'VALIDATION_ERROR' && e.details != null) {
      final errors = (e.details['errors'] as List<dynamic>?)
              ?.map((err) => FieldError(
                    field: err['field'] ?? '',
                    message: err['message'] ?? '',
                  ))
              .toList() ??
          [];
      return ValidationFailure(message: e.message, errors: errors);
    }

    // Network errors
    if (e is NetworkException) {
      return const NetworkFailure();
    }

    // Auth-specific errors
    if (e.statusCode == 401 || e.statusCode == 403) {
      return AuthFailure(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }

    // Generic server error
    return ServerFailure(
      code: e.code,
      message: e.message,
      details: e.details,
    );
  }
}
