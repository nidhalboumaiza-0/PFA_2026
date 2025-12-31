part of 'doctor_appointment_bloc.dart';

abstract class DoctorAppointmentEvent extends Equatable {
  const DoctorAppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDoctorAppointments extends DoctorAppointmentEvent {
  final String? status;
  final DateTime? date;
  final int page;
  final int limit;

  const LoadDoctorAppointments({
    this.status,
    this.date,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, date, page, limit];
}

class LoadAppointmentRequests extends DoctorAppointmentEvent {
  final int page;
  final int limit;

  const LoadAppointmentRequests({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

class LoadDoctorSchedule extends DoctorAppointmentEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadDoctorSchedule({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class SetDoctorAvailability extends DoctorAppointmentEvent {
  final DateTime date;
  final List<String> timeSlots;
  final String? specialNotes;

  const SetDoctorAvailability({
    required this.date,
    required this.timeSlots,
    this.specialNotes,
  });

  @override
  List<Object?> get props => [date, timeSlots, specialNotes];
}

/// Bulk set availability for multiple dates (from template)
class BulkSetDoctorAvailability extends DoctorAppointmentEvent {
  final List<AvailabilityEntry> availabilities;
  final bool skipExisting;

  const BulkSetDoctorAvailability({
    required this.availabilities,
    this.skipExisting = true,
  });

  @override
  List<Object?> get props => [availabilities, skipExisting];
}

/// Single availability entry for bulk operations
class AvailabilityEntry {
  final DateTime date;
  final List<String> timeSlots;
  final String? specialNotes;

  const AvailabilityEntry({
    required this.date,
    required this.timeSlots,
    this.specialNotes,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'slots': timeSlots.map((t) => {'time': t}).toList(),
    'specialNotes': specialNotes,
  };
}

class ConfirmAppointmentRequest extends DoctorAppointmentEvent {
  final String appointmentId;

  const ConfirmAppointmentRequest({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}

class RejectAppointmentRequest extends DoctorAppointmentEvent {
  final String appointmentId;
  final String reason;

  const RejectAppointmentRequest({
    required this.appointmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}

class CompleteAppointmentAction extends DoctorAppointmentEvent {
  final String appointmentId;
  final String? notes;

  const CompleteAppointmentAction({
    required this.appointmentId,
    this.notes,
  });

  @override
  List<Object?> get props => [appointmentId, notes];
}

class RescheduleByDoctor extends DoctorAppointmentEvent {
  final String appointmentId;
  final DateTime newDate;
  final String newTime;
  final String? reason;

  const RescheduleByDoctor({
    required this.appointmentId,
    required this.newDate,
    required this.newTime,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, newDate, newTime, reason];
}

class ApprovePatientReschedule extends DoctorAppointmentEvent {
  final String appointmentId;

  const ApprovePatientReschedule({required this.appointmentId});

  @override
  List<Object?> get props => [appointmentId];
}

class RejectPatientReschedule extends DoctorAppointmentEvent {
  final String appointmentId;
  final String? reason;

  const RejectPatientReschedule({
    required this.appointmentId,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}

class LoadAppointmentStatistics extends DoctorAppointmentEvent {
  const LoadAppointmentStatistics();
}

class CancelByDoctor extends DoctorAppointmentEvent {
  final String appointmentId;
  final String reason;

  const CancelByDoctor({
    required this.appointmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}

class SelectScheduleDate extends DoctorAppointmentEvent {
  final DateTime date;
  final List<String>? slots;

  const SelectScheduleDate({
    required this.date,
    this.slots,
  });

  @override
  List<Object?> get props => [date, slots];
}

/// Event triggered by WebSocket to refresh appointments
class RefreshDoctorAppointments extends DoctorAppointmentEvent {
  final String? appointmentId;
  final String? eventType;

  const RefreshDoctorAppointments({
    this.appointmentId,
    this.eventType,
  });

  @override
  List<Object?> get props => [appointmentId, eventType];
}

/// Event triggered by WebSocket when new appointment request comes in
class OnNewAppointmentRequest extends DoctorAppointmentEvent {
  final Map<String, dynamic>? data;

  const OnNewAppointmentRequest({this.data});

  @override
  List<Object?> get props => [data];
}
