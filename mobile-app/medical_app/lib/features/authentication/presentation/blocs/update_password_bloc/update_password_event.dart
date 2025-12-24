part of 'update_password_bloc.dart';

abstract class UpdatePasswordEvent extends Equatable {
  const UpdatePasswordEvent();

  @override
  List<Object> get props => [];
}

class UpdatePasswordSubmitted extends UpdatePasswordEvent {
  final String email;
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordSubmitted({
    required this.email,
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, currentPassword, newPassword];
} 