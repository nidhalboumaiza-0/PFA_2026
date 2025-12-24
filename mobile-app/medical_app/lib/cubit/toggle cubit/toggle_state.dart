part of 'toggle_cubit.dart';

@immutable
sealed class ToggleState extends Equatable {

  @override
  List<Object> get props => [];
}

final class PatientState extends ToggleState {

}

final class MedecinState extends ToggleState {
}
