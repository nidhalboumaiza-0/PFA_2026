import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.isRead,
    super.readAt,
    super.resourceType,
    super.resourceId,
    super.actionUrl,
    super.actionData,
    super.priority,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.fromString(json['type'] ?? ''),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      resourceType: json['relatedResource']?['resourceType'],
      resourceId: json['relatedResource']?['resourceId']?.toString(),
      actionUrl: json['actionUrl'],
      actionData: json['actionData'] != null
          ? Map<String, dynamic>.from(json['actionData'])
          : null,
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'isRead': isRead,
        'readAt': readAt?.toIso8601String(),
        'relatedResource': {
          'resourceType': resourceType,
          'resourceId': resourceId,
        },
        'actionUrl': actionUrl,
        'actionData': actionData,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
      };
}
