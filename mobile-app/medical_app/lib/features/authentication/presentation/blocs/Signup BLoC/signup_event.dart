part of 'signup_bloc.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object> get props => [];
}

class SignupWithUserEntity extends SignupEvent {
  final UserEntity user;
  final String password;

  const SignupWithUserEntity({required this.user, required this.password});

  @override
  List<Object> get props => [user, password];
}