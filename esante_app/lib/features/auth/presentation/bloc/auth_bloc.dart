import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/push_notification_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final PushNotificationService _pushService = PushNotificationService();

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
      (data) async {
        _log('_onLoginRequested', 'Login success! User: ${data.$1.email}');
        emit(AuthSuccess(user: data.$1, tokens: data.$2));
        
        // Register device for push notifications after successful login
        _registerDeviceForPushNotifications(data.$1.id);
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

    // Unregister device from push notifications before logout
    await _unregisterDeviceFromPushNotifications();

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

  /// Register device for push notifications with backend
  Future<void> _registerDeviceForPushNotifications(String userId) async {
    try {
      _log('_registerDeviceForPushNotifications', 'Registering device for user: $userId');
      
      // Set external user ID for targeting
      await _pushService.setExternalUserId(userId);
      
      // Set user tags for segmentation
      await _pushService.setUserTags({
        'user_id': userId,
        'logged_in': 'true',
      });
      
      // Register device with backend
      await _pushService.registerDeviceWithBackend();
      
      _log('_registerDeviceForPushNotifications', 'Device registration complete');
    } catch (e) {
      _log('_registerDeviceForPushNotifications', 'Error: $e');
    }
  }

  /// Unregister device from push notifications
  Future<void> _unregisterDeviceFromPushNotifications() async {
    try {
      _log('_unregisterDeviceFromPushNotifications', 'Unregistering device');
      
      // Remove external user ID
      await _pushService.removeExternalUserId();
      
      // Unregister from backend
      await _pushService.unregisterDeviceFromBackend();
      
      _log('_unregisterDeviceFromPushNotifications', 'Device unregistration complete');
    } catch (e) {
      _log('_unregisterDeviceFromPushNotifications', 'Error: $e');
    }
  }
}
