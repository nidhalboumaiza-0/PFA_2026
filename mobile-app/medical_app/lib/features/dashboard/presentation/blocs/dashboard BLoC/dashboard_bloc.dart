import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/dashboard_stats_entity.dart';
import '../../../domain/usecases/get_doctor_dashboard_stats_use_case.dart';
import '../../../domain/usecases/get_upcoming_appointments_use_case.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDoctorDashboardStatsUseCase getDoctorDashboardStatsUseCase;
  final GetUpcomingAppointmentsUseCase getUpcomingAppointmentsUseCase;

  DashboardBloc({
    required this.getDoctorDashboardStatsUseCase,
    required this.getUpcomingAppointmentsUseCase,
  }) : super(DashboardInitial()) {
    on<FetchDoctorDashboardStats>(_onFetchDoctorDashboardStats);
    on<FetchUpcomingAppointments>(_onFetchUpcomingAppointments);
  }

  Future<void> _onFetchDoctorDashboardStats(
    FetchDoctorDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await getDoctorDashboardStatsUseCase(event.doctorId);
    emit(_eitherLoadedOrErrorState(result));
  }

  Future<void> _onFetchUpcomingAppointments(
    FetchUpcomingAppointments event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await getUpcomingAppointmentsUseCase(
      event.doctorId,
      limit: event.limit,
    );
    emit(_eitherAppointmentsLoadedOrErrorState(result));
  }

  DashboardState _eitherLoadedOrErrorState(
    Either<Failure, DashboardStatsEntity> failureOrStats,
  ) {
    return failureOrStats.fold(
      (failure) => DashboardError(message: _mapFailureToMessage(failure)),
      (stats) => DashboardLoaded(dashboardStats: stats),
    );
  }

  DashboardState _eitherAppointmentsLoadedOrErrorState(
    Either<Failure, List<AppointmentEntity>> failureOrAppointments,
  ) {
    return failureOrAppointments.fold(
      (failure) => DashboardError(message: _mapFailureToMessage(failure)),
      (appointments) => AppointmentsLoaded(appointments: appointments),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Une erreur est survenue lors de la communication avec le serveur';
      case ServerMessageFailure:
        return (failure as ServerMessageFailure).message;
      case OfflineFailure:
        return 'Veuillez vérifier votre connexion Internet';
      default:
        return 'Une erreur inattendue s\'est produite';
    }
  }
} 