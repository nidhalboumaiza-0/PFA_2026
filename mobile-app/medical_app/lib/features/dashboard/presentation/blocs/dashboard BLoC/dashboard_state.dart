import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard_stats_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStatsEntity dashboardStats;
  
  const DashboardLoaded({required this.dashboardStats});
  
  @override
  List<Object?> get props => [dashboardStats];
}

class AppointmentsLoaded extends DashboardState {
  final List<AppointmentEntity> appointments;
  
  const AppointmentsLoaded({required this.appointments});
  
  @override
  List<Object?> get props => [appointments];
}

class AppointmentCountsLoaded extends DashboardState {
  final Map<String, int> counts;
  
  const AppointmentCountsLoaded({required this.counts});
  
  @override
  List<Object?> get props => [counts];
}

class PatientCountLoaded extends DashboardState {
  final int count;
  
  const PatientCountLoaded({required this.count});
  
  @override
  List<Object?> get props => [count];
}

class DashboardError extends DashboardState {
  final String message;
  
  const DashboardError({required this.message});
  
  @override
  List<Object> get props => [message];
} 