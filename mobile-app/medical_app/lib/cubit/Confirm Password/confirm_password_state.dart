part of 'confirm_password_cubit.dart';

@immutable
sealed class ConfirmPasswordState extends Equatable{
  @override
  List<Object> get props => [];
}

class ConfirmPasswordVisible extends ConfirmPasswordState {}
class ConfirmPasswordInVisible extends ConfirmPasswordState {}