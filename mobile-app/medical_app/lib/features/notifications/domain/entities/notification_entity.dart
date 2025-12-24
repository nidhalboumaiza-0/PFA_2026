import 'package:equatable/equatable.dart';

/// Notification types matching backend enum
enum NotificationType {
  appointmentConfirmed,
  appointmentRejected,
  appointmentReminder,
  appointmentCancelled,
  newMessage,
  referralReceived,
  referralScheduled,
  consultationCreated,
  prescriptionCreated,
  documentUploaded,
  systemAlert,
  // Legacy types for backwards compatibility
  general,
  appointment,
  prescription,
  message,
  medicalRecord,
  newAppointment,
  appointmentAccepted,
  rating,
  newPrescription,
}

/// Extension on NotificationType for string conversion
extension NotificationTypeExtension on NotificationType {
  /// Get the backend string value for this notification type
  String get value {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return 'appointment_confirmed';
      case NotificationType.appointmentRejected:
        return 'appointment_rejected';
      case NotificationType.appointmentReminder:
        return 'appointment_reminder';
      case NotificationType.appointmentCancelled:
        return 'appointment_cancelled';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.referralReceived:
        return 'referral_received';
      case NotificationType.referralScheduled:
        return 'referral_scheduled';
      case NotificationType.consultationCreated:
        return 'consultation_created';
      case NotificationType.prescriptionCreated:
        return 'prescription_created';
      case NotificationType.documentUploaded:
        return 'document_uploaded';
      case NotificationType.systemAlert:
        return 'system_alert';
      // Legacy types
      case NotificationType.general:
        return 'general';
      case NotificationType.appointment:
        return 'appointment';
      case NotificationType.prescription:
        return 'prescription';
      case NotificationType.message:
        return 'message';
      case NotificationType.medicalRecord:
        return 'medical_record';
      case NotificationType.newAppointment:
        return 'new_appointment';
      case NotificationType.appointmentAccepted:
        return 'appointment_accepted';
      case NotificationType.rating:
        return 'rating';
      case NotificationType.newPrescription:
        return 'new_prescription';
    }
  }

  /// Parse a string value to NotificationType
  static NotificationType fromString(String value) {
    switch (value) {
      case 'appointment_confirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointment_rejected':
        return NotificationType.appointmentRejected;
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'appointment_cancelled':
        return NotificationType.appointmentCancelled;
      case 'new_message':
        return NotificationType.newMessage;
      case 'referral_received':
        return NotificationType.referralReceived;
      case 'referral_scheduled':
        return NotificationType.referralScheduled;
      case 'consultation_created':
        return NotificationType.consultationCreated;
      case 'prescription_created':
        return NotificationType.prescriptionCreated;
      case 'document_uploaded':
        return NotificationType.documentUploaded;
      case 'system_alert':
        return NotificationType.systemAlert;
      // Legacy types
      case 'general':
        return NotificationType.general;
      case 'appointment':
        return NotificationType.appointment;
      case 'prescription':
        return NotificationType.prescription;
      case 'message':
        return NotificationType.message;
      case 'medical_record':
        return NotificationType.medicalRecord;
      case 'new_appointment':
        return NotificationType.newAppointment;
      case 'appointment_accepted':
        return NotificationType.appointmentAccepted;
      case 'rating':
        return NotificationType.rating;
      case 'new_prescription':
        return NotificationType.newPrescription;
      default:
        return NotificationType.general;
    }
  }
}

/// Notification priority enum
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

/// Related resource for notification
class RelatedResource extends Equatable {
  final String? resourceType; // 'appointment', 'message', 'referral', 'consultation', 'prescription', 'document'
  final String? resourceId;

  const RelatedResource({
    this.resourceType,
    this.resourceId,
  });

  @override
  List<Object?> get props => [resourceType, resourceId];
}

/// Channel delivery status
class ChannelStatus extends Equatable {
  final bool enabled;
  final bool sent;
  final DateTime? sentAt;
  final String? error;

  const ChannelStatus({
    this.enabled = true,
    this.sent = false,
    this.sentAt,
    this.error,
  });

  @override
  List<Object?> get props => [enabled, sent, sentAt, error];
}

/// Notification channels
class NotificationChannels extends Equatable {
  final ChannelStatus push;
  final ChannelStatus email;
  final ChannelStatus inApp;

  const NotificationChannels({
    this.push = const ChannelStatus(),
    this.email = const ChannelStatus(),
    this.inApp = const ChannelStatus(enabled: true, sent: true),
  });

  @override
  List<Object?> get props => [push, email, inApp];
}

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String userType; // 'patient', 'doctor', 'admin'
  final String title;
  final String body;
  final NotificationType type;
  final RelatedResource? relatedResource;
  final NotificationChannels? channels;
  final bool isRead;
  final DateTime? readAt;
  final NotificationPriority priority;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Legacy fields for backwards compatibility
  final String? senderId;
  final String? recipientId;
  final String? appointmentId;
  final String? prescriptionId;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.userId,
    this.userType = 'patient',
    required this.title,
    required this.body,
    required this.type,
    this.relatedResource,
    this.channels,
    this.isRead = false,
    this.readAt,
    this.priority = NotificationPriority.medium,
    this.actionUrl,
    this.actionData,
    this.scheduledFor,
    required this.createdAt,
    this.updatedAt,
    // Legacy
    this.senderId,
    this.recipientId,
    this.appointmentId,
    this.prescriptionId,
    this.data,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? userType,
    String? title,
    String? body,
    NotificationType? type,
    RelatedResource? relatedResource,
    NotificationChannels? channels,
    bool? isRead,
    DateTime? readAt,
    NotificationPriority? priority,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderId,
    String? recipientId,
    String? appointmentId,
    String? prescriptionId,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedResource: relatedResource ?? this.relatedResource,
      channels: channels ?? this.channels,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      actionUrl: actionUrl ?? this.actionUrl,
      actionData: actionData ?? this.actionData,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      appointmentId: appointmentId ?? this.appointmentId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userType,
    title,
    body,
    type,
    relatedResource,
    channels,
    isRead,
    readAt,
    priority,
    actionUrl,
    actionData,
    scheduledFor,
    createdAt,
    updatedAt,
    senderId,
    recipientId,
    appointmentId,
    prescriptionId,
    data,
  ];
}
