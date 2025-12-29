import 'package:dio/dio.dart';
import '../storage/hive_storage_service.dart';
import 'api_list.dart';

/// Interceptor that automatically adds the Authorization header to requests
class AuthInterceptor extends Interceptor {
  void _log(String method, String message) {
    print('[AuthInterceptor.$method] $message');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('onRequest', 'Processing request to ${options.path}');
    
    // Skip auth header for login/register endpoints
    if (_isPublicEndpoint(options.path)) {
      _log('onRequest', 'Public endpoint, skipping auth header');
      return handler.next(options);
    }

    // Get the access token from storage
    final token = _getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _log('onRequest', 'Added Authorization header');
    } else {
      _log('onRequest', 'No token available');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('onError', 'Error: ${err.response?.statusCode} - ${err.message}');
    
    // Handle 401 Unauthorized - token might be expired
    if (err.response?.statusCode == 401) {
      _log('onError', 'Unauthorized - token may be expired');
      // TODO: Implement token refresh logic here
    }

    return handler.next(err);
  }

  bool _isPublicEndpoint(String path) {
    return ApiList.publicAuthEndpoints.any((publicPath) => path.contains(publicPath));
  }

  String? _getAccessToken() {
    try {
      final authBox = HiveStorageService.authBox;
      final token = authBox.get('access_token');
      _log('_getAccessToken', 'Token found: ${token != null ? 'Yes (${token.length} chars)' : 'No'}');
      return token;
    } catch (e) {
      _log('_getAccessToken', 'Error getting token: $e');
      return null;
    }
  }
}
