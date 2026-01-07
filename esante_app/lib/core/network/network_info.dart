import 'package:esante_app/core/services/connectivity_service.dart';

/// Abstract interface for network connectivity checking
abstract class NetworkInfo {
  /// Checks if the device is currently connected to the internet
  Future<bool> get isConnected;
}

/// Implementation of [NetworkInfo] that uses [ConnectivityService]
class NetworkInfoImpl implements NetworkInfo {
  final ConnectivityService connectivityService;

  NetworkInfoImpl({required this.connectivityService});

  @override
  Future<bool> get isConnected async {
    // First check the cached value, then optionally verify
    return connectivityService.isConnected;
  }
}
