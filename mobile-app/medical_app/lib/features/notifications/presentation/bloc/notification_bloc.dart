import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/usecases/usecase.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/send_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/initialize_onesignal_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/set_external_user_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_onesignal_player_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/save_onesignal_player_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/logout_onesignal_use_case.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final SendNotificationUseCase sendNotificationUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase markAllNotificationsAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final GetUnreadNotificationsCountUseCase getUnreadNotificationsCountUseCase;
  final InitializeOneSignalUseCase initializeOneSignalUseCase;
  final SetExternalUserIdUseCase setExternalUserIdUseCase;
  final GetOneSignalPlayerIdUseCase getOneSignalPlayerIdUseCase;
  final SaveOneSignalPlayerIdUseCase saveOneSignalPlayerIdUseCase;
  final LogoutOneSignalUseCase logoutOneSignalUseCase;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.sendNotificationUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllNotificationsAsReadUseCase,
    required this.deleteNotificationUseCase,
    required this.getUnreadNotificationsCountUseCase,
    required this.initializeOneSignalUseCase,
    required this.setExternalUserIdUseCase,
    required this.getOneSignalPlayerIdUseCase,
    required this.saveOneSignalPlayerIdUseCase,
    required this.logoutOneSignalUseCase,
  }) : super(NotificationInitial()) {
    on<GetNotificationsEvent>(_onGetNotifications);
    on<SendNotificationEvent>(_onSendNotification);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<GetUnreadNotificationsCountEvent>(_onGetUnreadNotificationsCount);
    on<InitializeOneSignalEvent>(_onInitializeOneSignal);
    on<SetExternalUserIdEvent>(_onSetExternalUserId);
    on<GetOneSignalPlayerIdEvent>(_onGetOneSignalPlayerId);
    on<SaveOneSignalPlayerIdEvent>(_onSaveOneSignalPlayerId);
    on<LogoutOneSignalEvent>(_onLogoutOneSignal);
    on<NotificationReceivedEvent>(_onNotificationReceived);
    on<NotificationErrorEvent>(_onNotificationError);
  }

  Future<void> _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getNotificationsUseCase(
      GetNotificationsParams(
        page: event.page,
        limit: event.limit,
        unreadOnly: event.unreadOnly,
        type: event.type?.value,
      ),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        _notifications = notifications;
        emit(NotificationsLoaded(notifications: notifications));
      },
    );
  }

  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await sendNotificationUseCase(
      SendNotificationParams(
        title: event.title,
        body: event.body,
        senderId: event.senderId,
        recipientId: event.recipientId,
        type: event.type,
        appointmentId: event.appointmentId,
        prescriptionId: event.prescriptionId,
        data: event.data,
      ),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(NotificationSent()),
    );
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await markNotificationAsReadUseCase(
      MarkNotificationAsReadParams(notificationId: event.notificationId),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(NotificationMarkedAsRead()),
    );
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await markAllNotificationsAsReadUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) {
        // Update local notifications list
        _notifications =
            _notifications.map((notification) {
              return notification.copyWith(isRead: true);
            }).toList();
        emit(AllNotificationsMarkedAsRead());
        emit(NotificationsLoaded(notifications: _notifications));
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await deleteNotificationUseCase(
      DeleteNotificationParams(notificationId: event.notificationId),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(NotificationDeleted()),
    );
  }

  Future<void> _onGetUnreadNotificationsCount(
    GetUnreadNotificationsCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getUnreadNotificationsCountUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (count) {
        _unreadCount = count;
        emit(UnreadNotificationsCountLoaded(count: count));
      },
    );
  }

  Future<void> _onInitializeOneSignal(
    InitializeOneSignalEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await initializeOneSignalUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(OneSignalInitialized()),
    );
  }

  Future<void> _onSetExternalUserId(
    SetExternalUserIdEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await setExternalUserIdUseCase(
      SetExternalUserIdParams(userId: event.userId),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(ExternalUserIdSet()),
    );
  }

  Future<void> _onGetOneSignalPlayerId(
    GetOneSignalPlayerIdEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await getOneSignalPlayerIdUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (playerId) => emit(OneSignalPlayerIdLoaded(playerId: playerId)),
    );
  }

  Future<void> _onSaveOneSignalPlayerId(
    SaveOneSignalPlayerIdEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await saveOneSignalPlayerIdUseCase(
      SaveOneSignalPlayerIdParams(userId: event.userId),
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(OneSignalPlayerIdSaved()),
    );
  }

  Future<void> _onLogoutOneSignal(
    LogoutOneSignalEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await logoutOneSignalUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(OneSignalLoggedOut()),
    );
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationsLoaded(notifications: _notifications));
    emit(UnreadNotificationsCountLoaded(count: _unreadCount));
  }

  void _onNotificationError(
    NotificationErrorEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationError(message: event.message));
  }
}
