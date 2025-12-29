part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;
  final AuthTokensEntity tokens;

  const AuthSuccess({required this.user, required this.tokens});

  @override
  List<Object?> get props => [user, tokens];
}

class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final Failure failure;

  const AuthError({required this.failure});

  /// Check if this error is due to unverified email
  bool get isEmailNotVerified => failure.code == 'EMAIL_NOT_VERIFIED';

  /// Get the error message
  String get message => failure.message;

  /// Get details (e.g., canResend for email verification)
  dynamic get details => failure.details;

  @override
  List<Object?> get props => [failure];
}

class ForgotPasswordSuccess extends AuthState {}

class LogoutSuccess extends AuthState {}
