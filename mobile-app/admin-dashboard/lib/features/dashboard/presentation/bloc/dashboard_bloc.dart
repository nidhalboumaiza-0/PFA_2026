import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_mapper.dart';
import '../../domain/entities/stats_entity.dart';
import '../../domain/usecases/get_appointments_per_day_usecase.dart';
import '../../domain/usecases/get_appointments_per_month_usecase.dart';
import '../../domain/usecases/get_appointments_per_year_usecase.dart';
import '../../domain/usecases/get_stats_usecase.dart';
import '../../domain/usecases/get_top_doctors_by_completed_appointments_usecase.dart';
import '../../domain/usecases/get_top_doctors_by_cancelled_appointments_usecase.dart';
import '../../domain/usecases/get_top_patients_by_cancelled_appointments_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetStatsUseCase getStatsUseCase;
  final GetAppointmentsPerDayUseCase getAppointmentsPerDayUseCase;
  final GetAppointmentsPerMonthUseCase getAppointmentsPerMonthUseCase;
  final GetAppointmentsPerYearUseCase getAppointmentsPerYearUseCase;
  final GetTopDoctorsByCompletedAppointmentsUseCase
  getTopDoctorsByCompletedAppointmentsUseCase;
  final GetTopDoctorsByCancelledAppointmentsUseCase
  getTopDoctorsByCancelledAppointmentsUseCase;
  final GetTopPatientsByCancelledAppointmentsUseCase
  getTopPatientsByCancelledAppointmentsUseCase;

  DashboardBloc({
    required this.getStatsUseCase,
    required this.getAppointmentsPerDayUseCase,
    required this.getAppointmentsPerMonthUseCase,
    required this.getAppointmentsPerYearUseCase,
    required this.getTopDoctorsByCompletedAppointmentsUseCase,
    required this.getTopDoctorsByCancelledAppointmentsUseCase,
    required this.getTopPatientsByCancelledAppointmentsUseCase,
  }) : super(DashboardInitial()) {
    on<LoadStats>(_onLoadStats);
    on<LoadAppointmentsPerDay>(_onLoadAppointmentsPerDay);
    on<LoadAppointmentsPerMonth>(_onLoadAppointmentsPerMonth);
    on<LoadAppointmentsPerYear>(_onLoadAppointmentsPerYear);
    on<LoadTopDoctorsByCompletedAppointments>(
      _onLoadTopDoctorsByCompletedAppointments,
    );
    on<LoadTopDoctorsByCancelledAppointments>(
      _onLoadTopDoctorsByCancelledAppointments,
    );
    on<LoadTopPatientsByCancelledAppointments>(
      _onLoadTopPatientsByCancelledAppointments,
    );
  }

  void _onLoadStats(LoadStats event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    final result = await getStatsUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (stats) => emit(StatsLoaded(stats: stats)),
    );
  }

  void _onLoadAppointmentsPerDay(
    LoadAppointmentsPerDay event,
    Emitter<DashboardState> emit,
  ) async {
    emit(AppointmentsPerDayLoading());

    final result = await getAppointmentsPerDayUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (data) => emit(AppointmentsPerDayLoaded(data: data)),
    );
  }

  void _onLoadAppointmentsPerMonth(
    LoadAppointmentsPerMonth event,
    Emitter<DashboardState> emit,
  ) async {
    emit(AppointmentsPerMonthLoading());

    final result = await getAppointmentsPerMonthUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (data) => emit(AppointmentsPerMonthLoaded(data: data)),
    );
  }

  void _onLoadAppointmentsPerYear(
    LoadAppointmentsPerYear event,
    Emitter<DashboardState> emit,
  ) async {
    emit(AppointmentsPerYearLoading());

    final result = await getAppointmentsPerYearUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (data) => emit(AppointmentsPerYearLoaded(data: data)),
    );
  }

  void _onLoadTopDoctorsByCompletedAppointments(
    LoadTopDoctorsByCompletedAppointments event,
    Emitter<DashboardState> emit,
  ) async {
    emit(TopDoctorsByCompletedAppointmentsLoading());

    final result = await getTopDoctorsByCompletedAppointmentsUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (doctors) =>
          emit(TopDoctorsByCompletedAppointmentsLoaded(doctors: doctors)),
    );
  }

  void _onLoadTopDoctorsByCancelledAppointments(
    LoadTopDoctorsByCancelledAppointments event,
    Emitter<DashboardState> emit,
  ) async {
    emit(TopDoctorsByCancelledAppointmentsLoading());

    final result = await getTopDoctorsByCancelledAppointmentsUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (doctors) =>
          emit(TopDoctorsByCancelledAppointmentsLoaded(doctors: doctors)),
    );
  }

  void _onLoadTopPatientsByCancelledAppointments(
    LoadTopPatientsByCancelledAppointments event,
    Emitter<DashboardState> emit,
  ) async {
    emit(TopPatientsByCancelledAppointmentsLoading());

    final result = await getTopPatientsByCancelledAppointmentsUseCase();

    result.fold(
      (failure) => emit(DashboardError(message: mapFailureToMessage(failure))),
      (patients) =>
          emit(TopPatientsByCancelledAppointmentsLoaded(patients: patients)),
    );
  }
}
