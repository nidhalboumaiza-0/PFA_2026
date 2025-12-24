part of 'update_password_bloc.dart';

abstract class UpdatePasswordState extends Equatable {
  const UpdatePasswordState();

  @override
  List<Object> get props => [];
}

class UpdatePasswordInitial extends UpdatePasswordState {}

class UpdatePasswordLoading extends UpdatePasswordState {}

class UpdatePasswordSuccess extends UpdatePasswordState {}

class UpdatePasswordError extends UpdatePasswordState {
  final String message;

  const UpdatePasswordError({required this.message});

  @override
  List<Object> get props => [message];
}
