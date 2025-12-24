import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class FetchDoctorDashboardStats extends DashboardEvent {
  final String doctorId;

  const FetchDoctorDashboardStats({required this.doctorId});

  @override
  List<Object> get props => [doctorId];
}

class FetchUpcomingAppointments extends DashboardEvent {
  final String doctorId;
  final int limit;

  const FetchUpcomingAppointments({
    required this.doctorId,
    this.limit = 5,
  });

  @override
  List<Object> get props => [doctorId, limit];
}

class FetchAppointmentCounts extends DashboardEvent {
  final String doctorId;

  const FetchAppointmentCounts({required this.doctorId});

  @override
  List<Object> get props => [doctorId];
}

class FetchPatientCount extends DashboardEvent {
  final String doctorId;

  const FetchPatientCount({required this.doctorId});

  @override
  List<Object> get props => [doctorId];
} 