part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {
  final bool isEmailPasswordLogin;

  const LoginLoading({this.isEmailPasswordLogin = true});

  @override
  List<Object> get props => [isEmailPasswordLogin];
}

class LoginSuccess extends LoginState {
  final UserEntity user;

  const LoginSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class LoginError extends LoginState {
  final String message;

  const LoginError({required this.message});

  @override
  List<Object> get props => [message];
}
