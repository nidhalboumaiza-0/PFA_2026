import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

import '../../../../../core/utils/map_failure_to_message.dart';
import '../../../domain/usecases/login_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;

  LoginBloc({required this.loginUseCase}) : super(LoginInitial()) {
    on<LoginWithEmailAndPassword>(_onLoginWithEmailAndPassword);
    on<LoginWithGoogle>(_onLoginWithGoogle);
  }

  void _onLoginWithEmailAndPassword(
    LoginWithEmailAndPassword event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading(isEmailPasswordLogin: true));
    final failureOrUser = await loginUseCase(
      email: event.email,
      password: event.password,
    );
    failureOrUser.fold(
      (failure) => emit(LoginError(message: mapFailureToMessage(failure))),
      (user) => emit(LoginSuccess(user: user)),
    );
  }

  void _onLoginWithGoogle(
    LoginWithGoogle event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading(isEmailPasswordLogin: false));
    try {
      await loginUseCase.authRepository.signInWithGoogle();

      // After signing in with Google, check if the user exists in Firebase Auth
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Check if this is a new or existing user
        final isNewUser =
            currentUser.metadata.creationTime?.millisecondsSinceEpoch ==
            currentUser.metadata.lastSignInTime?.millisecondsSinceEpoch;

        // For both new and existing users, we'll return the user data
        // The repository implementation already handles saving user data to Firestore
        emit(
          LoginSuccess(
            user: UserEntity(
              id: currentUser.uid,
              name: currentUser.displayName?.split(' ').first ?? '',
              lastName: currentUser.displayName?.split(' ').last ?? '',
              email: currentUser.email ?? '',
              role: 'patient', // Default role for Google Sign-In
              gender: 'Homme', // Default gender, can be updated later
              phoneNumber: currentUser.phoneNumber ?? '',
              dateOfBirth: null,
            ),
          ),
        );
      } else {
        emit(const LoginError(message: 'Google sign-in failed'));
      }
    } catch (e) {
      emit(LoginError(message: e.toString()));
    }
  }
}
