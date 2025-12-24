import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'confirm_password_state.dart';

class ConfirmPasswordCubit extends Cubit<ConfirmPasswordState> {
  ConfirmPasswordCubit() : super( ConfirmPasswordInVisible());

  void TogglePasswordVisibility(){
    if(state is ConfirmPasswordInVisible){
      emit(ConfirmPasswordVisible());
    }else{
      emit(ConfirmPasswordInVisible());
    }
  }
}
