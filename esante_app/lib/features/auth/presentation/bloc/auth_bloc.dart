import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../../../core/error/failures.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.forgotPasswordUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ResetAuthState>(_onResetAuthState);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _log(String method, String message) {
    print('[AuthBloc.$method] $message');
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('_onLoginRequested', 'Login requested for: ${event.email}');
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    _log('_onLoginRequested', 'UseCase result received');

    result.fold(
      (failure) {
        _log('_onLoginRequested', 'Login failed: ${failure.message}');
        emit(AuthError(failure: failure));
      },
      (data) {
        _log('_onLoginRequested', 'Login success! User: ${data.$1.email}');
        emit(AuthSuccess(user: data.$1, tokens: data.$2));
      },
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await forgotPasswordUseCase(
      ForgotPasswordParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (_) => emit(ForgotPasswordSuccess()),
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      RegisterParams(
        email: event.email,
        password: event.password,
        role: event.role,
        profileData: event.profileData,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure: failure)),
      (message) => emit(AuthRegistrationSuccess(message: message)),
    );
  }

  void _onResetAuthState(ResetAuthState event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('_onLogoutRequested', 'Logout requested');
    emit(AuthLoading());

    final result = await logoutUseCase(
      LogoutParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _log('_onLogoutRequested', 'Logout failed: ${failure.message}');
        // Even if API fails, still logout locally
        emit(LogoutSuccess());
      },
      (_) {
        _log('_onLogoutRequested', 'Logout success');
        emit(LogoutSuccess());
      },
    );
  }
}
