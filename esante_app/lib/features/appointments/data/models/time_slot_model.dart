import '../../domain/entities/time_slot_entity.dart';

/// Data model for TimeSlot from API
class TimeSlotModel extends TimeSlotEntity {
  const TimeSlotModel({
    required super.id,
    required super.doctorId,
    required super.date,
    required super.slots,
    super.isAvailable,
    super.specialNotes,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      slots: (json['slots'] as List<dynamic>?)
              ?.map((s) => SlotInfoModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: json['isAvailable'] ?? true,
      specialNotes: json['specialNotes'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'doctorId': doctorId,
        'date': date.toIso8601String(),
        'slots': slots.map((s) => (s as SlotInfoModel).toJson()).toList(),
        'isAvailable': isAvailable,
        'specialNotes': specialNotes,
      };
}

class SlotInfoModel extends SlotInfo {
  const SlotInfoModel({
    required super.time,
    super.isBooked,
    super.appointmentId,
  });

  factory SlotInfoModel.fromJson(Map<String, dynamic> json) {
    return SlotInfoModel(
      time: json['time'] ?? '',
      isBooked: json['isBooked'] ?? false,
      appointmentId: json['appointmentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'isBooked': isBooked,
        'appointmentId': appointmentId,
      };
}
