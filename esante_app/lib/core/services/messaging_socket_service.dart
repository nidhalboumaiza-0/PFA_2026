import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Event types for messaging socket events
enum MessagingSocketEventType {
  // Connection
  connected,
  disconnected,
  error,
  
  // Messages
  newMessage,
  messageSent,
  messageDelivered,
  messagesRead,
  
  // Typing
  userTyping,
  userStoppedTyping,
  
  // Presence
  userOnline,
  userOffline,
  
  // Read receipts
  markAsReadSuccess,
}

/// Represents a messaging socket event
class MessagingSocketEvent {
  final MessagingSocketEventType type;
  final Map<String, dynamic>? data;
  final String? message;

  const MessagingSocketEvent({
    required this.type,
    this.data,
    this.message,
  });

  @override
  String toString() => 'MessagingSocketEvent(type: $type, data: $data)';
}

/// Singleton service for managing messaging WebSocket connections
/// Connects to the messaging-service for real-time chat features
class MessagingSocketService {
  static final MessagingSocketService _instance = MessagingSocketService._internal();
  factory MessagingSocketService() => _instance;
  MessagingSocketService._internal();

  io.Socket? _socket;
  String? _currentToken;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Stream controller for broadcasting events
  final _eventController = StreamController<MessagingSocketEvent>.broadcast();

  /// Stream of messaging socket events
  Stream<MessagingSocketEvent> get eventStream => _eventController.stream;

  /// Check if currently connected
  bool get isConnected => _isConnected;

  void _log(String method, String message) {
    print('[MessagingSocketService.$method] $message');
  }

  /// Initialize socket connection with auth token
  Future<void> init(String token, {String? baseUrl}) async {
    if (_isConnecting) {
      _log('init', 'Connection already in progress');
      return;
    }

    if (_isConnected && _currentToken == token) {
      _log('init', 'Already connected with same token');
      return;
    }

    if (_socket != null) {
      await disconnect();
    }

    _isConnecting = true;
    _currentToken = token;

    // Connect to messaging-service via API Gateway on port 3000
    // The gateway proxies socket connections to the messaging-service
    final gatewayUrl = baseUrl ?? 'http://10.0.2.2:3000';
    _log('init', 'Connecting to messaging socket via gateway at $gatewayUrl/messaging');

    try {
      _socket = io.io(
        '$gatewayUrl/messaging',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(10)
            .setTimeout(60000)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
      
      _log('init', 'Messaging socket connection initiated');
    } catch (e) {
      _log('init', 'Error initializing socket: $e');
      _isConnecting = false;
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.error,
        message: 'Failed to initialize: $e',
      ));
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // ============== Connection Events ==============
    _socket!.onConnect((_) {
      _log('onConnect', 'Connected to messaging server');
      _isConnected = true;
      _isConnecting = false;
      _emitEvent(const MessagingSocketEvent(type: MessagingSocketEventType.connected));
    });

    _socket!.onDisconnect((_) {
      _log('onDisconnect', 'Disconnected from messaging server');
      _isConnected = false;
      _emitEvent(const MessagingSocketEvent(type: MessagingSocketEventType.disconnected));
    });

    _socket!.onConnectError((error) {
      _log('onConnectError', 'Connection error: $error');
      _isConnecting = false;
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.error,
        message: 'Connection error: $error',
      ));
    });

    // ============== Message Events ==============
    
    // New message received
    _socket!.on('new_message', (data) {
      _log('new_message', 'Received new message');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.newMessage,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // Message sent confirmation
    _socket!.on('message_sent', (data) {
      _log('message_sent', 'Message sent confirmed');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.messageSent,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // Message delivered to recipient
    _socket!.on('message_delivered', (data) {
      _log('message_delivered', 'Message delivered');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.messageDelivered,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // Messages marked as read by recipient
    _socket!.on('messages_read', (data) {
      _log('messages_read', 'Messages read by recipient');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.messagesRead,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // Mark as read success confirmation
    _socket!.on('mark_as_read_success', (data) {
      _log('mark_as_read_success', 'Mark as read confirmed');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.markAsReadSuccess,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // ============== Typing Events ==============
    
    // User started typing
    _socket!.on('user_typing', (data) {
      _log('user_typing', 'User is typing');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.userTyping,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // User stopped typing
    _socket!.on('user_stopped_typing', (data) {
      _log('user_stopped_typing', 'User stopped typing');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.userStoppedTyping,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // ============== Presence Events ==============
    
    // User came online
    _socket!.on('user_online', (data) {
      _log('user_online', 'User is online');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.userOnline,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // User went offline
    _socket!.on('user_offline', (data) {
      _log('user_offline', 'User is offline');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.userOffline,
        data: Map<String, dynamic>.from(data),
      ));
    });

    // ============== Error Events ==============
    _socket!.on('error', (data) {
      _log('error', 'Socket error: $data');
      _emitEvent(MessagingSocketEvent(
        type: MessagingSocketEventType.error,
        data: data is Map ? Map<String, dynamic>.from(data) : null,
        message: data.toString(),
      ));
    });
  }

  void _emitEvent(MessagingSocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  // ============== Emit Methods ==============

  /// Send a text message
  void sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? tempId,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) {
      _log('sendMessage', 'Not connected, cannot send message');
      return;
    }

    _socket!.emit('send_message', {
      'conversationId': conversationId,
      'receiverId': receiverId,
      'messageType': messageType,
      'content': content,
      'tempId': tempId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Start typing indicator
  void startTyping({
    required String conversationId,
    required String receiverId,
  }) {
    if (!_isConnected) return;

    _socket!.emit('typing_start', {
      'conversationId': conversationId,
      'receiverId': receiverId,
    });
  }

  /// Stop typing indicator
  void stopTyping({
    required String conversationId,
    required String receiverId,
  }) {
    if (!_isConnected) return;

    _socket!.emit('typing_stop', {
      'conversationId': conversationId,
      'receiverId': receiverId,
    });
  }

  /// Mark messages as read
  void markAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) {
    if (!_isConnected) return;

    _socket!.emit('mark_as_read', {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });
  }

  /// Join a conversation room (for grouped events)
  void joinConversation(String conversationId) {
    if (!_isConnected) return;

    _socket!.emit('join_conversation', {
      'conversationId': conversationId,
    });
  }

  /// Disconnect from socket
  Future<void> disconnect() async {
    _log('disconnect', 'Disconnecting from messaging socket');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _currentToken = null;
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
