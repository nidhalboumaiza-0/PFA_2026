import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_logged_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final IsLoggedInUseCase isLoggedInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.isLoggedInUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()) {
    on<LoginWithEmailAndPassword>(_onLoginWithEmailAndPassword);
    on<Logout>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<GetCurrentUser>(_onGetCurrentUser);
  }

  void _onLoginWithEmailAndPassword(
    LoginWithEmailAndPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final params = LoginParams(email: event.email, password: event.password);
    final result = await loginUseCase(params);

    result.fold(
      (failure) => emit(AuthError(message: mapFailureToMessage(failure))),
      (user) => emit(Authenticated(user: user)),
    );
  }

  void _onLogout(Logout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(message: mapFailureToMessage(failure))),
      (_) => emit(Unauthenticated()),
    );
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await isLoggedInUseCase();

    result.fold(
      (failure) => emit(Unauthenticated()),
      (isLoggedIn) =>
          isLoggedIn ? add(GetCurrentUser()) : emit(Unauthenticated()),
    );
  }

  void _onGetCurrentUser(GetCurrentUser event, Emitter<AuthState> emit) async {
    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user: user)),
    );
  }
}
