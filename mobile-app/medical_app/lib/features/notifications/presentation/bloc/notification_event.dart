import 'package:equatable/equatable.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class GetNotificationsEvent extends NotificationEvent {
  final int page;
  final int limit;
  final bool? unreadOnly;
  final NotificationType? type;

  const GetNotificationsEvent({
    this.page = 1,
    this.limit = 20,
    this.unreadOnly,
    this.type,
  });

  @override
  List<Object> get props => [page, limit];
}

class SendNotificationEvent extends NotificationEvent {
  final String title;
  final String body;
  final String senderId;
  final String recipientId;
  final NotificationType type;
  final String? appointmentId;
  final String? prescriptionId;
  final Map<String, dynamic>? data;

  const SendNotificationEvent({
    required this.title,
    required this.body,
    required this.senderId,
    required this.recipientId,
    required this.type,
    this.appointmentId,
    this.prescriptionId,
    this.data,
  });

  @override
  List<Object> get props => [title, body, senderId, recipientId, type];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsReadEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class GetUnreadNotificationsCountEvent extends NotificationEvent {}

class InitializeOneSignalEvent extends NotificationEvent {}

class SetExternalUserIdEvent extends NotificationEvent {
  final String userId;

  const SetExternalUserIdEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class GetOneSignalPlayerIdEvent extends NotificationEvent {}

class SaveOneSignalPlayerIdEvent extends NotificationEvent {
  final String userId;

  const SaveOneSignalPlayerIdEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LogoutOneSignalEvent extends NotificationEvent {}

class NotificationReceivedEvent extends NotificationEvent {
  final NotificationEntity notification;

  const NotificationReceivedEvent({required this.notification});

  @override
  List<Object> get props => [notification];
}

class NotificationErrorEvent extends NotificationEvent {
  final String message;

  const NotificationErrorEvent({required this.message});

  @override
  List<Object> get props => [message];
}

class GetNotificationsStreamEvent extends NotificationEvent {
  final String userId;

  const GetNotificationsStreamEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
