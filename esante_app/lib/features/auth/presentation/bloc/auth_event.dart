part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final Map<String, dynamic>? profileData;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.role,
    this.profileData,
  });

  @override
  List<Object?> get props => [email, password, role, profileData];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetAuthState extends AuthEvent {
  const ResetAuthState();
}

class LogoutRequested extends AuthEvent {
  final String sessionId;

  const LogoutRequested({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
