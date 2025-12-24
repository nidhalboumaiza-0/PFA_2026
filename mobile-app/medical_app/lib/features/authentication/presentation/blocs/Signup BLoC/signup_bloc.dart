import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/usecases/create_account_use_case.dart';

import '../../../../../core/utils/map_failure_to_message.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final CreateAccountUseCase createAccountUseCase;

  SignupBloc({required this.createAccountUseCase}) : super(SignupInitial()) {
    on<SignupWithUserEntity>(_onSignupWithUserEntity);
  }

  void _onSignupWithUserEntity(
      SignupWithUserEntity event,
      Emitter<SignupState> emit,
      ) async {
    emit(SignupLoading());
    final failureOrUnit = await createAccountUseCase(event.user, event.password);
    failureOrUnit.fold(
          (failure) => emit(SignupError(message: mapFailureToMessage(failure))),
          (_) => emit(SignupSuccess()),
    );
  }


}