import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/features/authentication/domain/usecases/logout_use_case.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';

// Events
abstract class LogoutEvent extends Equatable {
  const LogoutEvent();
  @override
  List<Object> get props => [];
}

class LogoutRequested extends LogoutEvent {}

// States
abstract class LogoutState extends Equatable {
  const LogoutState();
  @override
  List<Object> get props => [];
}

class LogoutInitial extends LogoutState {}
class LogoutLoading extends LogoutState {}
class LogoutSuccess extends LogoutState {}
class LogoutError extends LogoutState {
  final String message;
  const LogoutError(this.message);
  @override
  List<Object> get props => [message];
}

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final LogoutUseCase logoutUseCase;
  final ConversationRepository? conversationRepository;

  LogoutBloc({
    required this.logoutUseCase,
    this.conversationRepository,
  }) : super(LogoutInitial()) {
    on<LogoutRequested>((event, emit) async {
      emit(LogoutLoading());
      
      // Disconnect socket before logging out
      try {
        await conversationRepository?.disconnectFromSocket();
      } catch (_) {
        // Ignore socket disconnect errors
      }
      
      final result = await logoutUseCase();
      result.fold(
        (failure) => emit(LogoutError('Logout failed')), // We might want to force logout anyway
        (_) => emit(LogoutSuccess()),
      );
    });
  }
}
