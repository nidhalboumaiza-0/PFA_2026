import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'password_visibility_state.dart';

class PasswordVisibilityCubit extends Cubit<PasswordVisibilityState> {
  PasswordVisibilityCubit() : super(PasswordInVisibility());

  void toggle() {
    if (state is PasswordInVisibility) {
      emit(PasswordVisibility());
    } else {
      emit(PasswordInVisibility());
    }
  }
}
