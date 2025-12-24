import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final List<AppointmentEntity> upcomingAppointments;

  const DashboardStatsEntity({
    required this.totalPatients,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.upcomingAppointments,
  });

  @override
  List<Object?> get props => [
    totalPatients,
    totalAppointments,
    pendingAppointments,
    completedAppointments,
    cancelledAppointments,
    upcomingAppointments,
  ];
}

class AppointmentEntity extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime appointmentDate;
  final String status;
  final String? appointmentType;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.appointmentDate,
    required this.status,
    this.appointmentType,
  });

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    appointmentDate,
    status,
    appointmentType,
  ];
} 