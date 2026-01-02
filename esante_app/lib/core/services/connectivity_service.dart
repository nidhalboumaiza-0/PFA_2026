import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller for broadcasting connectivity changes
  final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();
  
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  /// Whether the device currently has network connectivity
  bool get isConnected => _isConnected;

  /// Stream of connectivity status changes
  Stream<bool> get onConnectivityChanged => _connectionStatusController.stream;

  /// Initialize the connectivity monitoring
  Future<void> init() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  /// Check current connectivity status
  Future<bool> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(results);
    return _isConnected;
  }

  /// Handle connectivity change events
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasConnection(results);
    
    // Only broadcast if status actually changed
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
      print('[ConnectivityService] Connection status changed: $_isConnected');
    }
  }

  /// Check if any of the results indicate a connection
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }

  /// Check connectivity manually (useful for retry operations)
  Future<bool> checkConnection() async {
    return await _checkConnectivity();
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
