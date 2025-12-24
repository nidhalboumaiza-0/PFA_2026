part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class LoadStats extends DashboardEvent {}

class LoadAppointmentsPerDay extends DashboardEvent {}

class LoadAppointmentsPerMonth extends DashboardEvent {}

class LoadAppointmentsPerYear extends DashboardEvent {}

class LoadTopDoctorsByCompletedAppointments extends DashboardEvent {}

class LoadTopDoctorsByCancelledAppointments extends DashboardEvent {}

class LoadTopPatientsByCancelledAppointments extends DashboardEvent {}
