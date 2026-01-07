import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Abstract class defining messaging data source operations
abstract class MessagingRemoteDataSource {
  /// Create or get existing conversation with a user
  Future<ConversationModel> createOrGetConversation({
    required String recipientId,
    required String recipientType,
  });

  /// Get list of user's conversations
  Future<List<ConversationModel>> getConversations({
    String? type,
    int page = 1,
    int limit = 20,
  });

  /// Get messages for a conversation
  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? before,
  });

  /// Mark messages as read in a conversation
  Future<void> markMessagesAsRead({
    required String conversationId,
  });

  /// Send a file message (via REST API, not socket)
  Future<MessageModel> sendFileMessage({
    required String conversationId,
    required String receiverId,
    required File file,
    String? caption,
  });

  /// Delete a message
  Future<void> deleteMessage({
    required String messageId,
  });

  /// Get unread message count
  Future<int> getUnreadCount();

  /// Search messages
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
    int page = 1,
    int limit = 20,
  });

  /// Get user's online status
  Future<bool> getUserOnlineStatus({
    required String userId,
  });
}

/// Implementation of MessagingRemoteDataSource
class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final ApiClient _apiClient;

  MessagingRemoteDataSourceImpl(this._apiClient);

  void _log(String method, String message) {
    print('[MessagingRemoteDataSource.$method] $message');
  }

  @override
  Future<ConversationModel> createOrGetConversation({
    required String recipientId,
    required String recipientType,
  }) async {
    _log('createOrGetConversation', 'Creating/getting conversation with $recipientId');

    final response = await _apiClient.post(
      ApiList.conversations,
      data: {
        'recipientId': recipientId,
        'recipientType': recipientType,
      },
    );

    return ConversationModel.fromJson(response['data']);
  }

  @override
  Future<List<ConversationModel>> getConversations({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    _log('getConversations', 'Fetching conversations (page: $page, type: $type)');

    final response = await _apiClient.get(
      ApiList.conversations,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      },
    );

    final List<dynamic> conversationsJson = response['data'] ?? [];
    return conversationsJson
        .map((json) => ConversationModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? before,
  }) async {
    _log('getConversationMessages', 'Fetching messages for $conversationId (page: $page)');

    final response = await _apiClient.get(
      ApiList.conversationMessages(conversationId),
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (before != null) 'before': before,
      },
    );

    // API returns {data: {conversationId, messages: [...]}}
    final data = response['data'];
    final List<dynamic> messagesJson = data is Map ? (data['messages'] ?? []) : (data ?? []);
    return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
  }

  @override
  Future<void> markMessagesAsRead({
    required String conversationId,
  }) async {
    _log('markMessagesAsRead', 'Marking messages as read for $conversationId');

    await _apiClient.put(
      ApiList.conversationMarkRead(conversationId),
      data: {},
    );
  }

  @override
  Future<MessageModel> sendFileMessage({
    required String conversationId,
    required String receiverId,
    required File file,
    String? caption,
  }) async {
    _log('sendFileMessage', 'Sending file message to $conversationId');

    // Determine messageType based on file extension
    final extension = file.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final messageType = isImage ? 'image' : 'document';

    final response = await _apiClient.uploadFile(
      ApiList.conversationSendFile(conversationId),
      file: file,
      fileFieldName: 'file',
      additionalData: {
        'receiverId': receiverId,
        'messageType': messageType,
        if (caption != null) 'caption': caption,
      },
    );

    return MessageModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    _log('deleteMessage', 'Deleting message $messageId');

    await _apiClient.delete(ApiList.deleteMessage(messageId));
  }

  @override
  Future<int> getUnreadCount() async {
    _log('getUnreadCount', 'Fetching unread count');

    final response = await _apiClient.get(ApiList.unreadCount);
    // API returns: {"data":{"totalUnread":1,"byConversation":[...]}}
    return response['data']?['totalUnread'] ?? response['totalUnread'] ?? 0;
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    _log('searchMessages', 'Searching messages for "$query"');

    final response = await _apiClient.get(
      ApiList.searchMessages,
      queryParameters: {
        'query': query,
        'page': page.toString(),
        'limit': limit.toString(),
        if (conversationId != null) 'conversationId': conversationId,
      },
    );

    final List<dynamic> messagesJson = response['data'] ?? [];
    return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
  }

  @override
  Future<bool> getUserOnlineStatus({
    required String userId,
  }) async {
    _log('getUserOnlineStatus', 'Checking online status for $userId');

    final response = await _apiClient.get(ApiList.userOnlineStatus(userId));
    return response['data']?['isOnline'] ?? response['isOnline'] ?? false;
  }
}
