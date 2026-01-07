import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Event types for WebSocket events
enum WebSocketEventType {
  appointmentUpdated,
  newAppointmentRequest,
  appointmentStatusChanged,
  appointmentConfirmed,
  appointmentRejected,
  appointmentCancelled,
  appointmentRescheduled,
  appointmentCompleted,
  connected,
  disconnected,
  error,
}

/// Represents a WebSocket event with type and data
class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic>? data;
  final String? message;

  const WebSocketEvent({
    required this.type,
    this.data,
    this.message,
  });

  @override
  String toString() => 'WebSocketEvent(type: $type, data: $data, message: $message)';
}

/// Singleton service for managing WebSocket connections using socket.io
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  String? _currentToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _lastLoggedDisconnect = false;

  // Stream controller for broadcasting events to listeners
  final _eventController = StreamController<WebSocketEvent>.broadcast();

  /// Stream of WebSocket events that BLoCs can listen to
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  /// Check if currently connected
  bool get isConnected => _isConnected;

  void _log(String method, String message) {
    print('[WebSocketService.$method] $message');
  }

  /// Initialize WebSocket connection with authentication token
  Future<void> init(String token, {String? baseUrl}) async {
    // Prevent multiple simultaneous connection attempts
    if (_isConnecting) {
      _log('init', 'Connection already in progress, skipping...');
      return;
    }

    // If already connected with same token, skip
    if (_isConnected && _currentToken == token) {
      _log('init', 'Already connected with same token, skipping...');
      return;
    }

    // Disconnect existing connection if any
    if (_socket != null) {
      await disconnect();
    }

    _isConnecting = true;
    _currentToken = token;

    // Connect to notification-service via API Gateway on port 3000
    // The gateway proxies /socket.io to notification-service
    final gatewayUrl = baseUrl ?? 'http://10.0.2.2:3000';
    _log('init', 'Connecting to WebSocket via gateway at $gatewayUrl with path /socket.io');

    try {
      // Use raw options map - OptionBuilder doesn't apply path correctly
      _socket = io.io(
        gatewayUrl,
        <String, dynamic>{
          'transports': ['websocket', 'polling'], // Allow fallback to polling
          'path': '/socket.io',
          'forceNew': true, // Force new connection
          'auth': {'token': token},
          'extraHeaders': {'Authorization': 'Bearer $token'},
          'autoConnect': false, // Manual connect after setup
          'reconnection': true,
          'reconnectionDelay': 2000,
          'reconnectionDelayMax': 10000,
          'reconnectionAttempts': 10,
          'timeout': 90000, // Match server timeout
        },
      );
      
      _log('init', 'Socket configured with path: /socket.io, forceNew: true');

      _setupEventListeners();
      
      _socket!.connect();
      
      _log('init', 'WebSocket connection initiated');
    } catch (e) {
      _log('init', 'Error initializing WebSocket: $e');
      _isConnecting = false;
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.error,
        message: 'Failed to initialize WebSocket: $e',
      ));
    }
  }

  /// Setup all event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _log('_setupEventListeners', 'Connected to WebSocket server');
      _isConnected = true;
      _isConnecting = false;
      _lastLoggedDisconnect = false;
      _emitEvent(const WebSocketEvent(type: WebSocketEventType.connected));
    });

    _socket!.onDisconnect((_) {
      // Only log once to avoid spam during reconnection attempts
      if (!_lastLoggedDisconnect) {
        _log('_setupEventListeners', 'Disconnected from WebSocket server');
        _lastLoggedDisconnect = true;
      }
      _isConnected = false;
      _emitEvent(const WebSocketEvent(type: WebSocketEventType.disconnected));
    });

    _socket!.onConnectError((error) {
      _log('_setupEventListeners', 'Connection error: $error');
      _isConnecting = false;
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.error,
        message: 'Connection error: $error',
      ));
    });

    _socket!.onError((error) {
      _log('_setupEventListeners', 'Socket error: $error');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.error,
        message: 'Socket error: $error',
      ));
    });

    _socket!.on('reconnect', (_) {
      _log('_setupEventListeners', 'Reconnected to WebSocket server');
      _isConnected = true;
      _emitEvent(const WebSocketEvent(type: WebSocketEventType.connected));
    });

    _socket!.on('reconnect_attempt', (attempt) {
      _log('_setupEventListeners', 'Reconnection attempt: $attempt');
    });

    _socket!.on('reconnect_failed', (_) {
      _log('_setupEventListeners', 'Reconnection failed');
      _isConnected = false;
    });

    // Appointment-specific events
    _socket!.on('appointment_updated', (data) {
      _log('_setupEventListeners', 'Received appointment_updated: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentUpdated,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('new_appointment_request', (data) {
      _log('_setupEventListeners', 'Received new_appointment_request: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.newAppointmentRequest,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_status_changed', (data) {
      _log('_setupEventListeners', 'Received appointment_status_changed: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentStatusChanged,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_confirmed', (data) {
      _log('_setupEventListeners', 'Received appointment_confirmed: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentConfirmed,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_rejected', (data) {
      _log('_setupEventListeners', 'Received appointment_rejected: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentRejected,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_cancelled', (data) {
      _log('_setupEventListeners', 'Received appointment_cancelled: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentCancelled,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_rescheduled', (data) {
      _log('_setupEventListeners', 'Received appointment_rescheduled: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentRescheduled,
        data: _parseEventData(data),
      ));
    });

    _socket!.on('appointment_completed', (data) {
      _log('_setupEventListeners', 'Received appointment_completed: $data');
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.appointmentCompleted,
        data: _parseEventData(data),
      ));
    });

    // Generic notification event - parse type and emit specific event
    _socket!.on('new_notification', (data) {
      _log('_setupEventListeners', 'Received new_notification: $data');
      final parsedData = _parseEventData(data);
      final notificationType = parsedData?['type']?.toString() ?? '';
      
      // Map notification type to WebSocketEventType
      final eventType = _mapNotificationTypeToEventType(notificationType);
      if (eventType != null) {
        _emitEvent(WebSocketEvent(
          type: eventType,
          data: parsedData,
        ));
      }
    });
  }

  /// Map notification type string to WebSocketEventType
  WebSocketEventType? _mapNotificationTypeToEventType(String notificationType) {
    switch (notificationType) {
      case 'appointment_confirmed':
        return WebSocketEventType.appointmentConfirmed;
      case 'appointment_rejected':
        return WebSocketEventType.appointmentRejected;
      case 'appointment_cancelled':
        return WebSocketEventType.appointmentCancelled;
      case 'appointment_reminder':
        return WebSocketEventType.appointmentUpdated;
      case 'new_appointment_request':
        return WebSocketEventType.newAppointmentRequest;
      default:
        if (notificationType.startsWith('appointment_')) {
          return WebSocketEventType.appointmentStatusChanged;
        }
        return null;
    }
  }

  /// Parse event data to Map
  Map<String, dynamic>? _parseEventData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  /// Emit event to stream
  void _emitEvent(WebSocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Join a specific room (e.g., for user-specific notifications)
  void joinRoom(String room) {
    if (_socket != null && _isConnected) {
      _log('joinRoom', 'Joining room: $room');
      _socket!.emit('join', {'room': room});
    }
  }

  /// Leave a specific room
  void leaveRoom(String room) {
    if (_socket != null && _isConnected) {
      _log('leaveRoom', 'Leaving room: $room');
      _socket!.emit('leave', {'room': room});
    }
  }

  /// Emit a custom event
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _log('emit', 'Emitting event $event: $data');
      _socket!.emit(event, data);
    } else {
      _log('emit', 'Cannot emit event - not connected');
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _log('disconnect', 'Disconnecting WebSocket...');
    _isConnected = false;
    _isConnecting = false;
    _currentToken = null;
    
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    _log('disconnect', 'WebSocket disconnected');
  }

  /// Dispose the service (call on app close)
  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
    _log('dispose', 'WebSocketService disposed');
  }

  /// Reconnect with current token
  Future<void> reconnect() async {
    if (_currentToken != null) {
      await init(_currentToken!);
    }
  }
}
