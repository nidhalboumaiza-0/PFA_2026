part of 'rendez_vous_bloc.dart';

abstract class RendezVousState extends Equatable {
  const RendezVousState();

  @override
  List<Object?> get props => [];
}

class RendezVousInitial extends RendezVousState {}

class RendezVousLoading extends RendezVousState {}

class RendezVousLoaded extends RendezVousState {
  final List<RendezVousEntity> rendezVous;

  const RendezVousLoaded(this.rendezVous);

  @override
  List<Object> get props => [rendezVous];
}

class DoctorsLoaded extends RendezVousState {
  final List<MedecinEntity> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object> get props => [doctors];
}

class DoctorDailyAppointmentsLoaded extends RendezVousState {
  final List<RendezVousEntity> appointments;
  final DateTime date;

  const DoctorDailyAppointmentsLoaded(this.appointments, this.date);

  @override
  List<Object> get props => [appointments, date];
}

class RendezVousError extends RendezVousState {
  final String message;

  const RendezVousError(this.message);

  @override
  List<Object> get props => [message];
}

class RendezVousStatusUpdated extends RendezVousState {}

class RendezVousCreated extends RendezVousState {
  final String? rendezVousId;
  final String? patientName;

  const RendezVousCreated({this.rendezVousId, this.patientName});

  @override
  List<Object?> get props => [rendezVousId, patientName];
}

class PastAppointmentsChecked extends RendezVousState {
  final int updatedCount;

  const PastAppointmentsChecked({required this.updatedCount});

  @override
  List<Object> get props => [updatedCount];
}

class UpdatingRendezVousState extends RendezVousState {}

class RendezVousStatusUpdatedState extends RendezVousState {
  final String id;
  final String status;

  const RendezVousStatusUpdatedState({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}

class AddingRendezVousState extends RendezVousState {}

class RendezVousAddedState extends RendezVousState {}

class RendezVousErrorState extends RendezVousState {
  final String message;

  const RendezVousErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

class AppointmentCancelled extends RendezVousState {
  final String appointmentId;

  const AppointmentCancelled(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

class RatingDoctorState extends RendezVousState {}

class DoctorRated extends RendezVousState {
  final String appointmentId;
  final double rating;

  const DoctorRated(this.appointmentId, this.rating);

  @override
  List<Object> get props => [appointmentId, rating];
}

class AppointmentAccepted extends RendezVousState {
  final String appointmentId;

  const AppointmentAccepted(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

class AppointmentRefused extends RendezVousState {
  final String appointmentId;

  const AppointmentRefused(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

// ==================== RESCHEDULE STATES ====================

/// State when reschedule operation is in progress
class ReschedulingAppointment extends RendezVousState {}

/// Doctor: Successfully rescheduled appointment
class AppointmentRescheduled extends RendezVousState {
  final String appointmentId;
  final DateTime newDate;
  final String newTime;

  const AppointmentRescheduled({
    required this.appointmentId,
    required this.newDate,
    required this.newTime,
  });

  @override
  List<Object> get props => [appointmentId, newDate, newTime];
}

/// Patient: Successfully requested reschedule
class RescheduleRequested extends RendezVousState {
  final String appointmentId;

  const RescheduleRequested(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Doctor: Successfully approved reschedule request
class RescheduleApproved extends RendezVousState {
  final String appointmentId;

  const RescheduleApproved(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Doctor: Successfully rejected reschedule request
class RescheduleRejected extends RendezVousState {
  final String appointmentId;

  const RescheduleRejected(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Error state for reschedule operations
class RescheduleError extends RendezVousState {
  final String message;

  const RescheduleError(this.message);

  @override
  List<Object> get props => [message];
}
