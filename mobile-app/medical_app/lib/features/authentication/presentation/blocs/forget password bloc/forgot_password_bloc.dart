import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/usecases/forgot_password_use_case.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordUseCase forgotPasswordUseCase;

  ForgotPasswordBloc({required this.forgotPasswordUseCase}) : super(ForgotPasswordInitial()) {
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onForgotPasswordRequested(
      ForgotPasswordRequested event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoading());
    final result = await forgotPasswordUseCase(event.email);
    emit(result.fold(
          (failure) {
        if (failure is ServerFailure) {
          return ForgotPasswordError(message: 'server_error');
        } else if (failure is AuthFailure) {
          return ForgotPasswordError(message: failure.message);
        } else {
          return ForgotPasswordError(message: 'unexpected_error');
        }
      },
          (_) => ForgotPasswordSuccess(),
    ));
  }
}