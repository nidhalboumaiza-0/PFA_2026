import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required String id,
    required String userId,
    String userType = 'patient',
    required String title,
    required String body,
    required NotificationType type,
    RelatedResource? relatedResource,
    NotificationChannels? channels,
    bool isRead = false,
    DateTime? readAt,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    DateTime? scheduledFor,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Legacy fields
    String? senderId,
    String? recipientId,
    String? appointmentId,
    String? prescriptionId,
    Map<String, dynamic>? data,
  }) : super(
         id: id,
         userId: userId,
         userType: userType,
         title: title,
         body: body,
         type: type,
         relatedResource: relatedResource,
         channels: channels,
         isRead: isRead,
         readAt: readAt,
         priority: priority,
         actionUrl: actionUrl,
         actionData: actionData,
         scheduledFor: scheduledFor,
         createdAt: createdAt,
         updatedAt: updatedAt,
         senderId: senderId,
         recipientId: recipientId,
         appointmentId: appointmentId,
         prescriptionId: prescriptionId,
         data: data,
       );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['recipientId'] as String? ?? '',
      userType: json['userType'] as String? ?? 'patient',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: _parseNotificationType(json['type'] as String?),
      relatedResource: json['relatedResource'] != null
          ? RelatedResource(
              resourceType: json['relatedResource']['resourceType'] as String?,
              resourceId: json['relatedResource']['resourceId'] as String?,
            )
          : null,
      channels: json['channels'] != null
          ? NotificationChannels(
              push: _parseChannelStatus(json['channels']['push']),
              email: _parseChannelStatus(json['channels']['email']),
              inApp: _parseChannelStatus(json['channels']['inApp']),
            )
          : null,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      priority: _parsePriority(json['priority'] as String?),
      actionUrl: json['actionUrl'] as String?,
      actionData: json['actionData'] != null
          ? Map<String, dynamic>.from(json['actionData'] as Map)
          : null,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      // Legacy fields
      senderId: json['senderId'] as String?,
      recipientId: json['recipientId'] as String?,
      appointmentId: json['appointmentId'] as String?,
      prescriptionId: json['prescriptionId'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }

  static ChannelStatus _parseChannelStatus(dynamic channelJson) {
    if (channelJson == null) return const ChannelStatus();
    return ChannelStatus(
      enabled: channelJson['enabled'] as bool? ?? true,
      sent: channelJson['sent'] as bool? ?? false,
      sentAt: channelJson['sentAt'] != null
          ? DateTime.tryParse(channelJson['sentAt'] as String)
          : null,
      error: channelJson['error'] as String?,
    );
  }

  static NotificationPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      case 'medium':
      default:
        return NotificationPriority.medium;
    }
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
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
      // Legacy type mappings
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
      case 'newAppointment':
        return NotificationType.newAppointment;
      case 'appointmentAccepted':
        return NotificationType.appointmentAccepted;
      case 'rating':
        return NotificationType.rating;
      case 'newPrescription':
        return NotificationType.newPrescription;
      default:
        return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
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
      default:
        return type.toString().split('.').last;
    }
  }

  static String _priorityToString(NotificationPriority priority) {
    return priority.toString().split('.').last;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'userType': userType,
      'title': title,
      'body': body,
      'type': _typeToString(type),
      'isRead': isRead,
      'priority': _priorityToString(priority),
    };

    if (id.isNotEmpty) {
      data['_id'] = id;
    }

    if (relatedResource != null) {
      data['relatedResource'] = {
        'resourceType': relatedResource!.resourceType,
        'resourceId': relatedResource!.resourceId,
      };
    }

    if (actionUrl != null) {
      data['actionUrl'] = actionUrl;
    }

    if (actionData != null) {
      data['actionData'] = actionData;
    }

    if (scheduledFor != null) {
      data['scheduledFor'] = scheduledFor!.toIso8601String();
    }

    // Legacy fields
    if (senderId != null) {
      data['senderId'] = senderId;
    }

    if (recipientId != null) {
      data['recipientId'] = recipientId;
    }

    if (appointmentId != null) {
      data['appointmentId'] = appointmentId;
    }

    if (prescriptionId != null) {
      data['prescriptionId'] = prescriptionId;
    }

    if (this.data != null) {
      data['data'] = this.data;
    }

    return data;
  }

  @override
  NotificationModel copyWith({
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
    return NotificationModel(
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
}
