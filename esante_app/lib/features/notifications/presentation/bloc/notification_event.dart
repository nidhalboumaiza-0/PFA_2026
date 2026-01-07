part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final bool refresh;
  final bool unreadOnly;

  const LoadNotifications({
    this.refresh = false,
    this.unreadOnly = false,
  });

  @override
  List<Object?> get props => [refresh, unreadOnly];
}

class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class RefreshUnreadCount extends NotificationEvent {
  const RefreshUnreadCount();
}

class AddNewNotification extends NotificationEvent {
  final NotificationEntity notification;

  const AddNewNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}
