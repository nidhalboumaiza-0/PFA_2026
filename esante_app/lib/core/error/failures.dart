import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String code;
  final String message;
  final dynamic details;

  const Failure({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [code, message, details];
}

/// Server failure (API errors)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Validation failure (form errors)
class ValidationFailure extends Failure {
  final List<FieldError> errors;

  const ValidationFailure({
    required super.message,
    required this.errors,
  }) : super(code: 'VALIDATION_ERROR');

  @override
  List<Object?> get props => [code, message, errors];
}

class FieldError extends Equatable {
  final String field;
  final String message;

  const FieldError({required this.field, required this.message});

  @override
  List<Object?> get props => [field, message];
}

/// Network failure (no internet)
class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(
          code: 'NETWORK_ERROR',
          message: 'No internet connection. Please check your network.',
        );
}

/// Cache failure (local storage errors)
class CacheFailure extends Failure {
  const CacheFailure()
      : super(
          code: 'CACHE_ERROR',
          message: 'Unable to access local storage.',
        );
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    required super.code,
    required super.message,
    super.details,
  });
}
