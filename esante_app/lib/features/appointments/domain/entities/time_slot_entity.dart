import 'package:equatable/equatable.dart';

/// Entity representing a doctor's time slot for a day
class TimeSlotEntity extends Equatable {
  final String id;
  final String doctorId;
  final DateTime date;
  final List<SlotInfo> slots;
  final bool isAvailable;
  final String? specialNotes;

  const TimeSlotEntity({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.slots,
    this.isAvailable = true,
    this.specialNotes,
  });

  /// Get only available (not booked) slots
  List<SlotInfo> get availableSlots =>
      slots.where((s) => !s.isBooked).toList();

  /// Get only booked slots
  List<SlotInfo> get bookedSlots => slots.where((s) => s.isBooked).toList();

  /// Check if a specific time is available
  bool isTimeAvailable(String time) {
    if (!isAvailable) return false;
    final slot = slots.firstWhere(
      (s) => s.time == time,
      orElse: () => const SlotInfo(time: '', isBooked: true),
    );
    return !slot.isBooked;
  }

  @override
  List<Object?> get props =>
      [id, doctorId, date, slots, isAvailable, specialNotes];
}

/// Individual slot within a TimeSlot
class SlotInfo extends Equatable {
  final String time;
  final bool isBooked;
  final String? appointmentId;

  const SlotInfo({
    required this.time,
    this.isBooked = false,
    this.appointmentId,
  });

  @override
  List<Object?> get props => [time, isBooked, appointmentId];
}

/// Request model for setting availability
class SetAvailabilityParams extends Equatable {
  final DateTime date;
  final List<String> timeSlots;
  final String? specialNotes;

  const SetAvailabilityParams({
    required this.date,
    required this.timeSlots,
    this.specialNotes,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'slots': timeSlots,
        'specialNotes': specialNotes,
      };

  @override
  List<Object?> get props => [date, timeSlots, specialNotes];
}
