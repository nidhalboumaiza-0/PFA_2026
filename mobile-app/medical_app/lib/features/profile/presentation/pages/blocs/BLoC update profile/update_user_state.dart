part of 'update_user_bloc.dart';

abstract class UpdateUserState extends Equatable {
  const UpdateUserState();

  @override
  List<Object> get props => [];
}

class UpdateUserInitial extends UpdateUserState {}

class UpdateUserLoading extends UpdateUserState {}

class UpdateUserSuccess extends UpdateUserState {
  final UserEntity user;

  const UpdateUserSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class UpdateUserFailure extends UpdateUserState {
  final String message;

  const UpdateUserFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ChangePasswordLoading extends UpdateUserState {}

class ChangePasswordSuccess extends UpdateUserState {}

class ChangePasswordFailure extends UpdateUserState {
  final String message;

  const ChangePasswordFailure(this.message);

  @override
  List<Object> get props => [message];
}