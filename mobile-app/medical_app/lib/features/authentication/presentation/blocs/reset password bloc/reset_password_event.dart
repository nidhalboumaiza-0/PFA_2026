part of 'reset_password_bloc.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object> get props => [];
}

class ResetPasswordSubmitted extends ResetPasswordEvent {
  final String email;
  final String newPassword;
  final String token;

  const ResetPasswordSubmitted({
    required this.email,
    required this.newPassword,
    required this.token,
  });

  @override
  List<Object> get props => [email, newPassword, token];
}