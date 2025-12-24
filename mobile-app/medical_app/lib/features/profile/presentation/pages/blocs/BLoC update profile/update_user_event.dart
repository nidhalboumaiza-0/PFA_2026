part of 'update_user_bloc.dart';

abstract class UpdateUserEventBase extends Equatable {
  const UpdateUserEventBase();

  @override
  List<Object> get props => [];
}

class UpdateUserEvent extends UpdateUserEventBase {
  final UserEntity user;

  const UpdateUserEvent(this.user);

  @override
  List<Object> get props => [user];
}

class ChangePasswordRequested extends UpdateUserEventBase {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}