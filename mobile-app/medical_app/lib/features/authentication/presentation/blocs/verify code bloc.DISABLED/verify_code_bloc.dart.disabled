import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/features/authentication/domain/usecases/verify_code_use_case.dart';

part 'verify_code_event.dart';
part 'verify_code_state.dart';

class VerifyCodeBloc extends Bloc<VerifyCodeEvent, VerifyCodeState> {
  final VerifyCodeUseCase verifyCodeUseCase;

  VerifyCodeBloc({required this.verifyCodeUseCase}) : super(VerifyCodeInitial()) {
    on<VerifyCodeSubmitted>(_onVerifyCodeSubmitted);
  }

  Future<void> _onVerifyCodeSubmitted(
      VerifyCodeSubmitted event,
      Emitter<VerifyCodeState> emit,
      ) async {
    emit(VerifyCodeLoading());
    final result = await verifyCodeUseCase(
      email: event.email,
      verificationCode: event.verificationCode,
      codeType: event.codeType,
    );
    result.fold(
          (failure) {
        if (failure is ServerFailure) {
          emit(VerifyCodeError(message: 'server_error'));
        } else if (failure is AuthFailure) {
          emit(VerifyCodeError(message: failure.message));
        } else {
          emit(VerifyCodeError(message: 'unexpected_error'));
        }
      },
          (_) => emit(VerifyCodeSuccess(verificationCode: event.verificationCode)),
    );
  }
}