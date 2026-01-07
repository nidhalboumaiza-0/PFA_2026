import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  
  static const int _pageLimit = 20;

  NotificationBloc({required this.repository})
      : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
    on<AddNewNotification>(_onAddNewNotification);
  }

  void _log(String method, String message) {
    print('[NotificationBloc.$method] $message');
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    _log('_onLoadNotifications', 'Loading notifications, refresh=${event.refresh}');

    if (!event.refresh) {
      emit(const NotificationLoading());
    }

    final result = await repository.getNotifications(
      page: 1,
      limit: _pageLimit,
      unreadOnly: event.unreadOnly ? true : null,
    );

    await result.fold(
      (failure) async {
        _log('_onLoadNotifications', 'Error: ${failure.message}');
        emit(NotificationError(failure.message));
      },
      (notifications) async {
        _log('_onLoadNotifications', 'Loaded ${notifications.length} notifications');
        
        // Get unread count
        final countResult = await repository.getUnreadCount();
        final unreadCount = countResult.fold((_) => 0, (count) => count);

        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
          hasMore: notifications.length >= _pageLimit,
          currentPage: 1,
        ));
      },
    );
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded || !currentState.hasMore) return;

    _log('_onLoadMoreNotifications', 'Loading page ${currentState.currentPage + 1}');

    final result = await repository.getNotifications(
      page: currentState.currentPage + 1,
      limit: _pageLimit,
    );

    result.fold(
      (failure) {
        _log('_onLoadMoreNotifications', 'Error: ${failure.message}');
      },
      (newNotifications) {
        emit(currentState.copyWith(
          notifications: [...currentState.notifications, ...newNotifications],
          hasMore: newNotifications.length >= _pageLimit,
          currentPage: currentState.currentPage + 1,
        ));
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    _log('_onMarkAsRead', 'Marking ${event.notificationId} as read');

    final result = await repository.markAsRead(event.notificationId);

    result.fold(
      (failure) {
        _log('_onMarkAsRead', 'Error: ${failure.message}');
      },
      (updatedNotification) {
        final updatedList = currentState.notifications.map((n) {
          if (n.id == event.notificationId) {
            return updatedNotification;
          }
          return n;
        }).toList();

        final newUnreadCount = updatedList.where((n) => !n.isRead).length;

        emit(currentState.copyWith(
          notifications: updatedList,
          unreadCount: newUnreadCount,
        ));
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    _log('_onMarkAllAsRead', 'Marking all as read');

    final result = await repository.markAllAsRead();

    result.fold(
      (failure) {
        _log('_onMarkAllAsRead', 'Error: ${failure.message}');
      },
      (_) {
        // Refresh the list
        add(const LoadNotifications(refresh: true));
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    _log('_onDeleteNotification', 'Deleting ${event.notificationId}');

    final result = await repository.deleteNotification(event.notificationId);

    result.fold(
      (failure) {
        _log('_onDeleteNotification', 'Error: ${failure.message}');
      },
      (_) {
        final updatedList = currentState.notifications
            .where((n) => n.id != event.notificationId)
            .toList();

        final newUnreadCount = updatedList.where((n) => !n.isRead).length;

        emit(currentState.copyWith(
          notifications: updatedList,
          unreadCount: newUnreadCount,
        ));
      },
    );
  }

  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    final result = await repository.getUnreadCount();

    result.fold(
      (failure) {},
      (count) {
        emit(currentState.copyWith(unreadCount: count));
      },
    );
  }

  void _onAddNewNotification(
    AddNewNotification event,
    Emitter<NotificationState> emit,
  ) {
    final currentState = state;
    if (currentState is! NotificationsLoaded) {
      emit(NotificationsLoaded(
        notifications: [event.notification],
        unreadCount: 1,
      ));
      return;
    }

    emit(currentState.copyWith(
      notifications: [event.notification, ...currentState.notifications],
      unreadCount: currentState.unreadCount + 1,
    ));
  }
}
