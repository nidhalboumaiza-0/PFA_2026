import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/messagerie/domain/entities/message_entity.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';

/// User info needed for socket connection
class SocketUserInfo {
  final String? id;
  final String? name;
  final String? token;

  const SocketUserInfo({this.id, this.name, this.token});
}

/// Socket.IO service for real-time messaging
/// Handles connection to messaging-service websocket
class SocketService {
  final SocketUserInfo Function() userInfoGetter;
  final NetworkInfo networkInfo;
  final String baseUrl;

  io.Socket? _socket;
  String? _currentToken; // Track the token used for current connection
  
  // Stream controllers for real-time events
  final StreamController<MessageEntity> _messageController =
      StreamController<MessageEntity>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _onlineStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageDeliveredController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageSentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  SocketService({
    required this.userInfoGetter,
    required this.networkInfo,
    required this.baseUrl,
  });

  // Public streams
  Stream<MessageEntity> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;
  Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;
  Stream<Map<String, dynamic>> get messageDeliveredStream => _messageDeliveredController.stream;
  Stream<Map<String, dynamic>> get messageSentStream => _messageSentController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  bool get isConnected => _isConnected;

  /// Get current user info (always fresh)
  SocketUserInfo get _userInfo => userInfoGetter();

  /// Connect to Socket.IO server
  /// If [forceReconnect] is true, will disconnect and reconnect even if already connected
  Future<void> connect({bool forceReconnect = false}) async {
    final userInfo = _userInfo;
    
    // Force reconnect if requested (e.g., app resumed from background)
    if (forceReconnect && _socket != null) {
      debugPrint('Force reconnecting socket...');
      // Check if socket is actually connected
      if (_socket!.connected) {
        debugPrint('Socket is still connected, no need to reconnect');
        _isConnected = true;
        _connectionStatusController.add(true);
        return;
      } else {
        debugPrint('Socket was disconnected, reconnecting...');
        disconnect();
      }
    }
    
    // Check if we need to reconnect with a new token
    if (_isConnected && _socket?.connected == true && _currentToken == userInfo.token) {
      debugPrint('Socket already connected with current token');
      return;
    }
    
    // If connected but token changed, disconnect first
    if (_currentToken != null && _currentToken != userInfo.token) {
      debugPrint('Token changed, reconnecting socket...');
      disconnect();
    }

    final hasNetwork = await networkInfo.isConnected;
    if (!hasNetwork) {
      throw NetworkFailure();
    }

    try {
      if (userInfo.id == null || userInfo.token == null) {
        debugPrint('Cannot connect socket: missing user ID or token');
        throw AuthFailure();
      }

      _initializeSocket(userInfo.token!);
      _currentToken = userInfo.token;
    } catch (e) {
      debugPrint('Socket connection error: $e');
      throw ServerFailure();
    }
  }

  void _initializeSocket(String token) {
    try {
      // Dispose existing socket if any
      _socket?.dispose();
      
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()              // Enable auto-reconnect
            .setReconnectionAttempts(10)       // Try 10 times before giving up
            .setReconnectionDelay(1000)        // Wait 1 second between attempts
            .setReconnectionDelayMax(10000)    // Max delay of 10 seconds
            .setAuth({'token': token})         // JWT token for auth
            .build(),
      );

      _socket!.connect();

      // Connection events
      _socket!.onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        debugPrint('Socket connected');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _connectionStatusController.add(false);
        debugPrint('Socket disconnected');
      });

      _socket!.onReconnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        debugPrint('Socket reconnected');
      });

      _socket!.onReconnectAttempt((attemptNumber) {
        debugPrint('Socket reconnection attempt: $attemptNumber');
      });

      _socket!.onReconnectError((data) {
        debugPrint('Socket reconnection error: $data');
      });

      _socket!.onReconnectFailed((_) {
        debugPrint('Socket reconnection failed after all attempts');
      });

      _socket!.onConnectError((data) {
        _isConnected = false;
        debugPrint('Socket connection error: $data');
      });

      _socket!.onError((data) {
        debugPrint('Socket error: $data');
      });

      // Listen for new messages
      _socket!.on('new_message', (data) {
        try {
          final messageData = _parseData(data);
          final message = MessageModel.fromJson(messageData);
          _messageController.add(message);
        } catch (e) {
          debugPrint('Error parsing new_message: $e');
        }
      });

      // Listen for message sent confirmation
      _socket!.on('message_sent', (data) {
        try {
          final sentData = _parseData(data);
          _messageSentController.add({
            'tempId': sentData['tempId'],
            'messageId': sentData['messageId'],
            'timestamp': sentData['timestamp'],
          });
        } catch (e) {
          debugPrint('Error parsing message_sent: $e');
        }
      });

      // Listen for message delivered confirmation
      _socket!.on('message_delivered', (data) {
        try {
          final deliveredData = _parseData(data);
          _messageDeliveredController.add({
            'messageId': deliveredData['messageId'],
            'deliveredAt': deliveredData['deliveredAt'],
          });
        } catch (e) {
          debugPrint('Error parsing message_delivered: $e');
        }
      });

      // Listen for typing start
      _socket!.on('user_typing', (data) {
        try {
          final typingData = _parseData(data);
          _typingController.add({
            'userId': typingData['userId'],
            'userName': typingData['userName'],
            'conversationId': typingData['conversationId'],
            'isTyping': true,
          });
        } catch (e) {
          debugPrint('Error parsing user_typing: $e');
        }
      });

      // Listen for typing stop
      _socket!.on('user_stopped_typing', (data) {
        try {
          final typingData = _parseData(data);
          _typingController.add({
            'userId': typingData['userId'],
            'conversationId': typingData['conversationId'],
            'isTyping': false,
          });
        } catch (e) {
          debugPrint('Error parsing user_stopped_typing: $e');
        }
      });

      // Listen for messages read
      _socket!.on('messages_read', (data) {
        try {
          final readData = _parseData(data);
          _readReceiptController.add({
            'conversationId': readData['conversationId'],
            'messageIds': readData['messageIds'],
            'readBy': readData['readBy'],
            'readAt': readData['readAt'],
          });
        } catch (e) {
          debugPrint('Error parsing messages_read: $e');
        }
      });

      // Listen for user online status
      _socket!.on('user_online', (data) {
        try {
          final onlineData = _parseData(data);
          _onlineStatusController.add({
            'userId': onlineData['userId'],
            'isOnline': true,
            'timestamp': onlineData['timestamp'],
          });
        } catch (e) {
          debugPrint('Error parsing user_online: $e');
        }
      });

      // Listen for user offline status
      _socket!.on('user_offline', (data) {
        try {
          final offlineData = _parseData(data);
          _onlineStatusController.add({
            'userId': offlineData['userId'],
            'isOnline': false,
            'lastSeen': offlineData['lastSeen'],
          });
        } catch (e) {
          debugPrint('Error parsing user_offline: $e');
        }
      });

      // Listen for errors
      _socket!.on('error', (data) {
        final errorData = _parseData(data);
        debugPrint('Socket error event: ${errorData['event']} - ${errorData['message']}');
      });

    } catch (e) {
      debugPrint('Socket initialization error: $e');
      throw ServerFailure();
    }
  }

  /// Parse socket data (handles both Map and encoded JSON)
  Map<String, dynamic> _parseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String) {
      return jsonDecode(data);
    } else {
      return jsonDecode(jsonEncode(data));
    }
  }

  /// Send a text message via Socket.IO
  /// Emits 'send_message' event
  void sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? tempId,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected || _socket == null) {
      throw ServerFailure();
    }

    final messageData = {
      'conversationId': conversationId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType,
      if (tempId != null) 'tempId': tempId,
      if (metadata != null) 'metadata': metadata,
    };

    _socket!.emit('send_message', messageData);
  }

  /// Send typing start indicator
  /// Emits 'typing_start' event
  void sendTypingIndicator({
    required String conversationId,
    required String recipientId,
    required bool isTyping,
  }) {
    if (!_isConnected || _socket == null) return;

    final eventName = isTyping ? 'typing_start' : 'typing_stop';
    final data = {
      'conversationId': conversationId,
      'receiverId': recipientId,
    };

    _socket!.emit(eventName, data);
  }

  /// Mark messages as read via Socket.IO
  /// Emits 'mark_as_read' event
  void markMessagesAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) {
    if (!_isConnected || _socket == null) return;

    final data = {
      'conversationId': conversationId,
      'messageIds': messageIds,
    };

    _socket!.emit('mark_as_read', data);
  }

  /// Join a conversation room
  /// Emits 'join_conversation' event
  void joinConversation(String conversationId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('join_conversation', {'conversationId': conversationId});
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('leave_conversation', {'conversationId': conversationId});
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentToken = null;
    _connectionStatusController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _readReceiptController.close();
    _onlineStatusController.close();
    _messageDeliveredController.close();
    _messageSentController.close();
    _connectionStatusController.close();
  }
}
