part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginWithEmailAndPassword extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailAndPassword({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class Logout extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class GetCurrentUser extends AuthEvent {}
