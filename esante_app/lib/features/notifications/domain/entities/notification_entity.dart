import 'package:equatable/equatable.dart';

enum NotificationType {
  appointmentConfirmed,
  appointmentRejected,
  appointmentCancelled,
  appointmentReminder,
  appointmentRescheduled,
  rescheduleRequested,
  newMessage,
  referralReceived,
  referralScheduled,
  prescriptionCreated,
  consultationCreated,
  newAppointmentRequest,
  general;

  static NotificationType fromString(String type) {
    switch (type) {
      case 'appointment_confirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointment_rejected':
        return NotificationType.appointmentRejected;
      case 'appointment_cancelled':
        return NotificationType.appointmentCancelled;
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'appointment_rescheduled':
        return NotificationType.appointmentRescheduled;
      case 'reschedule_requested':
        return NotificationType.rescheduleRequested;
      case 'new_message':
        return NotificationType.newMessage;
      case 'referral_received':
        return NotificationType.referralReceived;
      case 'referral_scheduled':
        return NotificationType.referralScheduled;
      case 'prescription_created':
        return NotificationType.prescriptionCreated;
      case 'consultation_created':
        return NotificationType.consultationCreated;
      case 'new_appointment_request':
        return NotificationType.newAppointmentRequest;
      default:
        return NotificationType.general;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return 'Appointment Confirmed';
      case NotificationType.appointmentRejected:
        return 'Appointment Rejected';
      case NotificationType.appointmentCancelled:
        return 'Appointment Cancelled';
      case NotificationType.appointmentReminder:
        return 'Appointment Reminder';
      case NotificationType.appointmentRescheduled:
        return 'Appointment Rescheduled';
      case NotificationType.rescheduleRequested:
        return 'Reschedule Request';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.referralReceived:
        return 'Referral Received';
      case NotificationType.referralScheduled:
        return 'Referral Scheduled';
      case NotificationType.prescriptionCreated:
        return 'New Prescription';
      case NotificationType.consultationCreated:
        return 'Consultation Notes';
      case NotificationType.newAppointmentRequest:
        return 'Appointment Request';
      case NotificationType.general:
        return 'Notification';
    }
  }
}

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime? readAt;
  final String? resourceType;
  final String? resourceId;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final String priority;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.readAt,
    this.resourceType,
    this.resourceId,
    this.actionUrl,
    this.actionData,
    this.priority = 'medium',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        isRead,
        readAt,
        resourceType,
        resourceId,
        actionUrl,
        actionData,
        priority,
        createdAt,
      ];
}
