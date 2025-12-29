/// Base exception class
abstract class AppException implements Exception {
  final String code;
  final String message;

  const AppException({required this.code, required this.message});
}

/// Server/API exception
class ServerException extends AppException {
  final int statusCode;
  final dynamic details;

  const ServerException({
    required super.code,
    required super.message,
    required this.statusCode,
    this.details,
  });

  /// Check if this is an email not verified error
  bool get isEmailNotVerified => code == 'EMAIL_NOT_VERIFIED';

  /// Check if user can resend verification
  bool get canResendVerification {
    if (details is Map<String, dynamic>) {
      return details['canResend'] == true;
    }
    return false;
  }

  @override
  String toString() => 'ServerException: [$code] $message';
}

/// Network exception (no internet)
class NetworkException extends ServerException {
  const NetworkException()
      : super(
          code: 'NETWORK_ERROR',
          message: 'No internet connection. Please check your network.',
          statusCode: 0,
        );
}

/// Cache/Local storage exception
class CacheException extends AppException {
  const CacheException({
    super.code = 'CACHE_ERROR',
    super.message = 'Unable to access local storage',
  });
}

/// Authentication exception (token expired, etc.)
class AuthException extends AppException {
  const AuthException({
    required super.code,
    required super.message,
  });
}
