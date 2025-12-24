part of 'password_visibility_cubit.dart';

@immutable
sealed class PasswordVisibilityState extends Equatable{
  const PasswordVisibilityState();

  @override
  List<Object> get props => [];
}

final class PasswordVisibility extends PasswordVisibilityState {
}
final class PasswordInVisibility extends PasswordVisibilityState {
}