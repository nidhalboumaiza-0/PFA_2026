import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  });

  Future<NotificationModel> markAsRead(String notificationId);

  Future<void> markAllAsRead();

  Future<int> getUnreadCount();

  Future<void> deleteNotification(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  void _log(String method, String message) {
    print('[NotificationRemoteDataSource.$method] $message');
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    _log('getNotifications', 'Fetching notifications page=$page');

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (unreadOnly == true) {
      queryParams['unreadOnly'] = true;
    }

    final response = await _apiClient.get(
      ApiList.notifications,
      queryParameters: queryParams,
    );

    final List<dynamic> notificationsJson = response['notifications'] ?? [];
    return notificationsJson
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    _log('markAsRead', 'Marking notification as read: $notificationId');

    final response = await _apiClient.put(
      ApiList.notificationMarkRead(notificationId),
    );

    return NotificationModel.fromJson(response['notification']);
  }

  @override
  Future<void> markAllAsRead() async {
    _log('markAllAsRead', 'Marking all notifications as read');
    await _apiClient.put(ApiList.notificationsMarkAllRead);
  }

  @override
  Future<int> getUnreadCount() async {
    _log('getUnreadCount', 'Fetching unread count');

    final response = await _apiClient.get(ApiList.notificationsUnreadCount);
    return response['unreadCount'] ?? 0;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    _log('deleteNotification', 'Deleting notification: $notificationId');
    await _apiClient.delete(ApiList.notificationDelete(notificationId));
  }
}
