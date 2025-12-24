import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/messagerie/data/models/conversation_model.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';

abstract class ConversationApiDataSource {
  /// Get user's conversations list
  /// GET /api/v1/messages/conversations
  Future<List<ConversationModel>> getConversations({
    int? page,
    int? limit,
    bool? archived,
  });

  /// Create or get existing conversation
  /// POST /api/v1/messages/conversations
  Future<ConversationModel> createOrGetConversation({
    required String participantId,
    required String participantType,
  });

  /// Get conversation messages (history)
  /// GET /api/v1/messages/conversations/:conversationId/messages
  Future<List<MessageModel>> getConversationMessages(
    String conversationId, {
    int? page,
    int? limit,
    DateTime? before,
  });

  /// Mark messages as read
  /// PUT /api/v1/messages/conversations/:conversationId/mark-read
  Future<void> markMessagesAsRead(String conversationId);

  /// Send message with file attachment
  /// POST /api/v1/messages/conversations/:conversationId/send-file
  Future<MessageModel> sendFileMessage({
    required String conversationId,
    required String filePath,
    String? messageType,
  });

  /// Get unread message count for user
  /// GET /api/v1/messages/unread-count
  Future<int> getUnreadCount();

  /// Search messages by content
  /// GET /api/v1/messages/search
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
    int? page,
    int? limit,
  });

  /// Check if user is online
  /// GET /api/v1/messages/users/:userId/online-status
  Future<bool> getOnlineStatus(String userId);

  /// Delete message (soft delete)
  /// DELETE /api/v1/messages/:messageId
  Future<void> deleteMessage(String messageId);
}

class ConversationApiDataSourceImpl implements ConversationApiDataSource {
  final http.Client client;
  final String baseUrl;
  final Map<String, String> Function() headersBuilder;
  final String? Function()? currentUserIdGetter;

  ConversationApiDataSourceImpl({
    required this.client,
    required this.baseUrl,
    required this.headersBuilder,
    this.currentUserIdGetter,
  });

  Map<String, String> get headers => headersBuilder();
  String? get currentUserId => currentUserIdGetter?.call();

  @override
  Future<List<ConversationModel>> getConversations({
    int? page,
    int? limit,
    bool? archived,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (archived != null) queryParams['archived'] = archived.toString();

      final uri = Uri.parse('$baseUrl/api/v1/messages/conversations')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> conversationsJson =
            jsonData['data']?['conversations'] ?? jsonData['data'] ?? [];

        return conversationsJson
            .map((json) => ConversationModel.fromJson(json, currentUserId: currentUserId))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to load conversations');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<ConversationModel> createOrGetConversation({
    required String participantId,
    required String participantType,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/messages/conversations'),
        headers: headers,
        body: json.encode({
          'recipientId': participantId,       // Backend expects 'recipientId'
          'recipientType': participantType,   // Backend expects 'recipientType'
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final conversationJson =
            jsonData['data']?['conversation'] ?? jsonData['data'];

        return ConversationModel.fromJson(conversationJson, currentUserId: currentUserId);
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to create conversation');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> getConversationMessages(
    String conversationId, {
    int? page,
    int? limit,
    DateTime? before,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (before != null) queryParams['before'] = before.toIso8601String();

      final uri = Uri.parse('$baseUrl/api/v1/messages/conversations/$conversationId/messages')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> messagesJson =
            jsonData['data']?['messages'] ?? jsonData['data'] ?? [];

        return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to load messages');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/api/v1/messages/conversations/$conversationId/mark-read'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to mark messages as read');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> sendFileMessage({
    required String conversationId,
    required String filePath,
    String? messageType,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/messages/conversations/$conversationId/send-file'),
      );

      // Add headers (excluding content-type as it's set automatically for multipart)
      headers.forEach((key, value) {
        if (key.toLowerCase() != 'content-type') {
          request.headers[key] = value;
        }
      });

      // Determine mime type from file extension
      final extension = filePath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'doc':
          mimeType = 'application/msword';
          break;
        case 'docx':
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      ));

      // Add message type if provided
      if (messageType != null) {
        request.fields['messageType'] = messageType;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final messageJson = jsonData['data']?['message'] ?? jsonData['data'];

        return MessageModel.fromJson(messageJson);
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to send file');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/messages/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data']?['count'] ?? jsonData['count'] ?? 0;
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to get unread count');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String query,
    String? conversationId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };
      if (conversationId != null) queryParams['conversationId'] = conversationId;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrl/api/v1/messages/search')
          .replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> messagesJson =
            jsonData['data']?['messages'] ?? jsonData['data'] ?? [];

        return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to search messages');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<bool> getOnlineStatus(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/messages/users/$userId/online-status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['data']?['isOnline'] ?? jsonData['isOnline'] ?? false;
      } else {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to get online status');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/v1/messages/$messageId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw ServerException(message: error['message'] ?? 'Failed to delete message');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }
}
