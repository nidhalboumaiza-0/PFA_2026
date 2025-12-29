part of 'patient_appointment_bloc.dart';

abstract class PatientAppointmentState extends Equatable {
  const PatientAppointmentState();

  @override
  List<Object?> get props => [];
}

class PatientAppointmentInitial extends PatientAppointmentState {}

class PatientAppointmentsLoading extends PatientAppointmentState {}

class DoctorAvailabilityLoading extends PatientAppointmentState {}

class AppointmentRequestLoading extends PatientAppointmentState {}

class AppointmentActionLoading extends PatientAppointmentState {}

class PatientAppointmentsLoaded extends PatientAppointmentState {
  final List<AppointmentEntity> appointments;
  final String? currentFilter;

  const PatientAppointmentsLoaded({
    required this.appointments,
    this.currentFilter,
  });

  List<AppointmentEntity> get upcomingAppointments => appointments
      .where((a) => a.isActive && a.appointmentDate.isAfter(DateTime.now()))
      .toList();

  List<AppointmentEntity> get pastAppointments => appointments
      .where((a) => a.isFinal || a.appointmentDate.isBefore(DateTime.now()))
      .toList();

  @override
  List<Object?> get props => [appointments, currentFilter];
}

class DoctorAvailabilityLoaded extends PatientAppointmentState {
  final String doctorId;
  final List<TimeSlotEntity> availability;
  final DateTime? selectedDate;
  final String? selectedTime;

  const DoctorAvailabilityLoaded({
    required this.doctorId,
    required this.availability,
    this.selectedDate,
    this.selectedTime,
  });

  /// Get dates that have availability
  List<DateTime> get availableDates =>
      availability.where((a) => a.isAvailable).map((a) => a.date).toList();

  /// Get slots for selected date
  List<SlotInfo> get slotsForSelectedDate {
    if (selectedDate == null) return [];
    try {
      final slot = availability.firstWhere(
        (a) =>
            a.date.year == selectedDate!.year &&
            a.date.month == selectedDate!.month &&
            a.date.day == selectedDate!.day,
      );
      return slot.availableSlots;
    } catch (_) {
      return [];
    }
  }

  bool get canBook => selectedDate != null && selectedTime != null;

  DoctorAvailabilityLoaded copyWith({
    String? doctorId,
    List<TimeSlotEntity>? availability,
    DateTime? selectedDate,
    String? selectedTime,
  }) {
    return DoctorAvailabilityLoaded(
      doctorId: doctorId ?? this.doctorId,
      availability: availability ?? this.availability,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }

  @override
  List<Object?> get props =>
      [doctorId, availability, selectedDate, selectedTime];
}

class AppointmentRequestSuccess extends PatientAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentRequestSuccess({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class AppointmentCancelled extends PatientAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentCancelled({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class RescheduleRequestSent extends PatientAppointmentState {
  final AppointmentEntity appointment;

  const RescheduleRequestSent({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class PatientAppointmentError extends PatientAppointmentState {
  final String message;

  const PatientAppointmentError({required this.message});

  @override
  List<Object?> get props => [message];
}
