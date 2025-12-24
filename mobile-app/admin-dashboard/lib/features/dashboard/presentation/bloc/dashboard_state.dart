part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class AppointmentsPerDayLoading extends DashboardState {}

class AppointmentsPerMonthLoading extends DashboardState {}

class AppointmentsPerYearLoading extends DashboardState {}

class TopDoctorsByCompletedAppointmentsLoading extends DashboardState {}

class TopDoctorsByCancelledAppointmentsLoading extends DashboardState {}

class TopPatientsByCancelledAppointmentsLoading extends DashboardState {}

class StatsLoaded extends DashboardState {
  final StatsEntity stats;

  const StatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AppointmentsPerDayLoaded extends DashboardState {
  final Map<String, int> data;

  const AppointmentsPerDayLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class AppointmentsPerMonthLoaded extends DashboardState {
  final Map<String, int> data;

  const AppointmentsPerMonthLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class AppointmentsPerYearLoaded extends DashboardState {
  final Map<String, int> data;

  const AppointmentsPerYearLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class TopDoctorsByCompletedAppointmentsLoaded extends DashboardState {
  final List<DoctorStatistics> doctors;

  const TopDoctorsByCompletedAppointmentsLoaded({required this.doctors});

  @override
  List<Object?> get props => [doctors];
}

class TopDoctorsByCancelledAppointmentsLoaded extends DashboardState {
  final List<DoctorStatistics> doctors;

  const TopDoctorsByCancelledAppointmentsLoaded({required this.doctors});

  @override
  List<Object?> get props => [doctors];
}

class TopPatientsByCancelledAppointmentsLoaded extends DashboardState {
  final List<PatientStatistics> patients;

  const TopPatientsByCancelledAppointmentsLoaded({required this.patients});

  @override
  List<Object?> get props => [patients];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
