import 'package:equatable/equatable.dart';

/// A general server-related exception with a message.
class ServerException extends Equatable implements Exception {
  final String message;

  ServerException({this.message = 'Server error occurred'});

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when the cache is empty.
class EmptyCacheException extends Equatable implements Exception {
  final String message;

  EmptyCacheException({this.message = 'Cache error occurred'});

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when there's no internet connection.
class OfflineException extends Equatable implements Exception {
  final String message;

  OfflineException({this.message = 'Network error occurred'});

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for server-specific error messages.
class ServerMessageException extends Equatable implements Exception {
  final String message;

  ServerMessageException({this.message = 'Server error occurred'});

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for unauthorized access.
class UnauthorizedException extends Equatable implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'unauthorized_failure_message']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when an API call times out.
class TimeoutException extends Equatable implements Exception {
  final String message;

  const TimeoutException([this.message = 'Request timed out']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for authentication-specific errors.
class AuthException extends Equatable implements Exception {
  final String message;

  AuthException({this.message = 'Authentication error occurred'});

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when email or phone number is already used.
class UsedEmailOrPhoneNumberException extends Equatable implements Exception {
  final String message;

  const UsedEmailOrPhoneNumberException([
    this.message = 'Email or phone number already used',
  ]);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when an inactive account's validation code has expired.
class YouHaveToCreateAccountAgainException extends Equatable
    implements Exception {
  final String message;

  const YouHaveToCreateAccountAgainException([
    this.message =
        'Account inactive and validation code expired. Please create a new account.',
  ]);

  @override
  List<Object?> get props => [message];
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Cache error occurred'});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Network error occurred'});
}

class ValidationException implements Exception {
  final String message;

  ValidationException({this.message = 'Validation error occurred'});
}

class PermissionException implements Exception {
  final String message;

  PermissionException({this.message = 'Permission denied'});
}

class FileException implements Exception {
  final String message;

  FileException({this.message = 'File error occurred'});
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException({this.message = 'Resource not found'});
}
