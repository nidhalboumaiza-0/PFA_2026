import 'package:equatable/equatable.dart';

class StatsEntity extends Equatable {
  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final Map<String, int> appointmentsPerDay;
  final Map<String, int> appointmentsPerMonth;
  final Map<String, int> appointmentsPerYear;

  // New statistics
  final List<DoctorStatistics> topDoctorsByCompletedAppointments;
  final List<DoctorStatistics> topDoctorsByCancelledAppointments;
  final List<PatientStatistics> topPatientsByCancelledAppointments;

  const StatsEntity({
    required this.totalUsers,
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.appointmentsPerDay,
    required this.appointmentsPerMonth,
    required this.appointmentsPerYear,
    this.topDoctorsByCompletedAppointments = const [],
    this.topDoctorsByCancelledAppointments = const [],
    this.topPatientsByCancelledAppointments = const [],
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalDoctors,
    totalPatients,
    totalAppointments,
    pendingAppointments,
    completedAppointments,
    cancelledAppointments,
    appointmentsPerDay,
    appointmentsPerMonth,
    appointmentsPerYear,
    topDoctorsByCompletedAppointments,
    topDoctorsByCancelledAppointments,
    topPatientsByCancelledAppointments,
  ];
}

class DoctorStatistics extends Equatable {
  final String id;
  final String name;
  final String email;
  final int appointmentCount;
  final double completionRate;

  const DoctorStatistics({
    required this.id,
    required this.name,
    required this.email,
    required this.appointmentCount,
    this.completionRate = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    appointmentCount,
    completionRate,
  ];
}

class PatientStatistics extends Equatable {
  final String id;
  final String name;
  final String email;
  final int cancelledAppointments;
  final int totalAppointments;
  final double cancellationRate;

  const PatientStatistics({
    required this.id,
    required this.name,
    required this.email,
    required this.cancelledAppointments,
    required this.totalAppointments,
    this.cancellationRate = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    cancelledAppointments,
    totalAppointments,
    cancellationRate,
  ];
}
