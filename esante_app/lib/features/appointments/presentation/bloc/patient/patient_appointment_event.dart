part of 'patient_appointment_bloc.dart';

abstract class PatientAppointmentEvent extends Equatable {
  const PatientAppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatientAppointments extends PatientAppointmentEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadPatientAppointments({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

class LoadDoctorAvailability extends PatientAppointmentEvent {
  final String doctorId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadDoctorAvailability({
    required this.doctorId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [doctorId, startDate, endDate];
}

class RequestAppointment extends PatientAppointmentEvent {
  final String doctorId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String reason;
  final String? notes;
  final List<PendingDocumentAttachment> attachments;

  const RequestAppointment({
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.reason,
    this.notes,
    this.attachments = const [],
  });

  @override
  List<Object?> get props =>
      [doctorId, appointmentDate, appointmentTime, reason, notes, attachments];
}

class CancelPatientAppointment extends PatientAppointmentEvent {
  final String appointmentId;
  final String reason;

  const CancelPatientAppointment({
    required this.appointmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}

class RequestPatientReschedule extends PatientAppointmentEvent {
  final String appointmentId;
  final DateTime newDate;
  final String newTime;
  final String? reason;

  const RequestPatientReschedule({
    required this.appointmentId,
    required this.newDate,
    required this.newTime,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, newDate, newTime, reason];
}

class SelectDate extends PatientAppointmentEvent {
  final DateTime date;

  const SelectDate({required this.date});

  @override
  List<Object?> get props => [date];
}

class SelectTimeSlot extends PatientAppointmentEvent {
  final String time;

  const SelectTimeSlot({required this.time});

  @override
  List<Object?> get props => [time];
}

class ClearBookingSelection extends PatientAppointmentEvent {
  const ClearBookingSelection();
}

/// Event triggered by WebSocket to refresh appointments
class RefreshPatientAppointments extends PatientAppointmentEvent {
  final String? appointmentId;
  final String? eventType;

  const RefreshPatientAppointments({
    this.appointmentId,
    this.eventType,
  });

  @override
  List<Object?> get props => [appointmentId, eventType];
}
