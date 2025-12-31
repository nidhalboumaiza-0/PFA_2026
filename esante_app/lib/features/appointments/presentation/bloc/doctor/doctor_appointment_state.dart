part of 'doctor_appointment_bloc.dart';

abstract class DoctorAppointmentState extends Equatable {
  const DoctorAppointmentState();

  @override
  List<Object?> get props => [];
}

class DoctorAppointmentInitial extends DoctorAppointmentState {}

class DoctorAppointmentsLoading extends DoctorAppointmentState {}

class AppointmentRequestsLoading extends DoctorAppointmentState {}

class DoctorScheduleLoading extends DoctorAppointmentState {}

class AppointmentActionLoading extends DoctorAppointmentState {}

class AvailabilityActionLoading extends DoctorAppointmentState {}

class StatisticsLoading extends DoctorAppointmentState {}

class DoctorAppointmentsLoaded extends DoctorAppointmentState {
  final List<AppointmentEntity> appointments;
  final String? currentFilter;
  final DateTime? selectedDate;

  const DoctorAppointmentsLoaded({
    required this.appointments,
    this.currentFilter,
    this.selectedDate,
  });

  List<AppointmentEntity> get todayAppointments {
    final now = DateTime.now();
    return appointments
        .where((a) =>
            a.appointmentDate.year == now.year &&
            a.appointmentDate.month == now.month &&
            a.appointmentDate.day == now.day)
        .toList();
  }

  List<AppointmentEntity> get upcomingAppointments => appointments
      .where((a) =>
          a.isActive &&
          a.appointmentDate.isAfter(DateTime.now().subtract(const Duration(days: 1))))
      .toList();

  @override
  List<Object?> get props => [appointments, currentFilter, selectedDate];
}

class AppointmentRequestsLoaded extends DoctorAppointmentState {
  final List<AppointmentEntity> requests;

  const AppointmentRequestsLoaded({required this.requests});

  int get pendingCount => requests.where((r) => r.isPending).length;

  @override
  List<Object?> get props => [requests];
}

class DoctorScheduleLoaded extends DoctorAppointmentState {
  final List<TimeSlotEntity> availability;
  final DateTime? selectedDate;
  final List<String> selectedSlots;

  const DoctorScheduleLoaded({
    required this.availability,
    this.selectedDate,
    this.selectedSlots = const [],
  });

  /// Get dates that already have availability set
  Map<DateTime, TimeSlotEntity> get availabilityMap {
    final map = <DateTime, TimeSlotEntity>{};
    for (final slot in availability) {
      final key = DateTime(slot.date.year, slot.date.month, slot.date.day);
      map[key] = slot;
    }
    return map;
  }

  DoctorScheduleLoaded copyWith({
    List<TimeSlotEntity>? availability,
    DateTime? selectedDate,
    List<String>? selectedSlots,
  }) {
    return DoctorScheduleLoaded(
      availability: availability ?? this.availability,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlots: selectedSlots ?? this.selectedSlots,
    );
  }

  @override
  List<Object?> get props => [availability, selectedDate, selectedSlots];
}

class AvailabilitySetSuccess extends DoctorAppointmentState {
  final TimeSlotEntity timeSlot;

  const AvailabilitySetSuccess({required this.timeSlot});

  @override
  List<Object?> get props => [timeSlot];
}

class BulkAvailabilitySetSuccess extends DoctorAppointmentState {
  final int created;
  final int updated;
  final int skipped;

  const BulkAvailabilitySetSuccess({
    required this.created,
    required this.updated,
    required this.skipped,
  });

  @override
  List<Object?> get props => [created, updated, skipped];
}

class AppointmentConfirmed extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentConfirmed({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class AppointmentRejected extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentRejected({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class AppointmentCompleted extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentCompleted({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class AppointmentRescheduled extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentRescheduled({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class AppointmentCancelledByDoctor extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const AppointmentCancelledByDoctor({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class RescheduleApproved extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const RescheduleApproved({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class RescheduleRejected extends DoctorAppointmentState {
  final AppointmentEntity appointment;

  const RescheduleRejected({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class StatisticsLoaded extends DoctorAppointmentState {
  final AppointmentStatistics statistics;

  const StatisticsLoaded({required this.statistics});

  @override
  List<Object?> get props => [statistics];
}

class DoctorAppointmentError extends DoctorAppointmentState {
  final String message;

  const DoctorAppointmentError({required this.message});

  @override
  List<Object?> get props => [message];
}
