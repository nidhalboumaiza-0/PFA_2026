import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/usecases/change_password_use_case.dart';

part 'update_password_event.dart';
part 'update_password_state.dart';

class UpdatePasswordBloc
    extends Bloc<UpdatePasswordEvent, UpdatePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  UpdatePasswordBloc({required this.changePasswordUseCase})
    : super(UpdatePasswordInitial()) {
    on<UpdatePasswordSubmitted>(_onUpdatePasswordSubmitted);
  }

  Future<void> _onUpdatePasswordSubmitted(
    UpdatePasswordSubmitted event,
    Emitter<UpdatePasswordState> emit,
  ) async {
    emit(UpdatePasswordLoading());

    final result = await changePasswordUseCase(
      oldPassword: event.currentPassword,
      newPassword: event.newPassword,
    );

    result.fold((failure) {
      if (failure is ServerFailure) {
        emit(UpdatePasswordError(message: 'server_error'));
      } else if (failure is AuthFailure) {
        emit(UpdatePasswordError(message: failure.message));
      } else if (failure is OfflineFailure) {
        emit(UpdatePasswordError(message: 'offline_failure_message'));
      } else {
        emit(UpdatePasswordError(message: 'unexpected_error'));
      }
    }, (_) => emit(UpdatePasswordSuccess()));
  }
}
