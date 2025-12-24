import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'toggle_state.dart';

class ToggleCubit extends Cubit<ToggleState> {
  ToggleCubit() : super(MedecinState());

  void toggle() {
    if (state is MedecinState) {
      emit(PatientState());
    } else {
      emit(MedecinState());
    }
  }


}
