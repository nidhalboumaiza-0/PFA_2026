import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/domain/usecases/update_user_use_case.dart';
import 'package:medical_app/core/services/api_service.dart';

part 'update_user_event.dart';
part 'update_user_state.dart';

class UpdateUserBloc extends Bloc<UpdateUserEventBase, UpdateUserState> {
  final UpdateUserUseCase updateUserUseCase;

  UpdateUserBloc({required this.updateUserUseCase}) : super(UpdateUserInitial()) {
    on<UpdateUserEvent>((event, emit) async {
      emit(UpdateUserLoading());
      final result = await updateUserUseCase(event.user);
      result.fold(
            (failure) => emit(UpdateUserFailure(_mapFailureToMessage(failure))),
            (_) => emit(UpdateUserSuccess(event.user)),
      );
    });

    on<ChangePasswordRequested>((event, emit) async {
      emit(ChangePasswordLoading());
      try {
        await ApiService.changePassword(event.currentPassword, event.newPassword);
        emit(ChangePasswordSuccess());
      } catch (e) {
        emit(ChangePasswordFailure(e.toString()));
      }
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case OfflineFailure:
        return 'No internet connection';
      case AuthFailure:
        return (failure as AuthFailure).message;
      default:
        return 'Unexpected error';
    }
  }
}