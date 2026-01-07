import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class ApiClient {
  final Dio _dio;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  ApiClient({required Dio dio}) : _dio = dio;

  void _log(String method, String message) {
    print('[ApiClient.$method] $message');
  }

  /// Check if error is retryable (connection issues)
  bool _isRetryableError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown ||
        (e.error?.toString().contains('Connection closed') ?? false);
  }

  /// GET request with automatic retry for connection errors
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _log('get', 'GET $path');
    
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.get(path, queryParameters: queryParameters);
        _log('get', 'Response status: ${response.statusCode}');
        return _handleResponse(response);
      } on DioException catch (e) {
        attempts++;
        if (_isRetryableError(e) && attempts <= _maxRetries) {
          _log('get', 'Retryable error, attempt $attempts/$_maxRetries. Retrying in ${_retryDelay.inMilliseconds}ms...');
          await Future.delayed(_retryDelay);
          continue;
        }
        _log('get', 'DioException: ${e.type} - ${e.message}');
        throw _handleDioError(e);
      }
    }
  }

  /// POST request with automatic retry for connection errors
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    _log('post', 'POST $path');
    
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
        );
        _log('post', 'Response status: ${response.statusCode}');
        return _handleResponse(response);
      } on DioException catch (e) {
        attempts++;
        if (_isRetryableError(e) && attempts <= _maxRetries) {
          _log('post', 'Retryable error, attempt $attempts/$_maxRetries. Retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        _log('post', 'DioException: ${e.type} - ${e.message}');
        throw _handleDioError(e);
      }
    }
  }

  /// PUT request with automatic retry for connection errors
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    _log('put', 'PUT $path');
    
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
        );
        _log('put', 'Response status: ${response.statusCode}');
        return _handleResponse(response);
      } on DioException catch (e) {
        attempts++;
        _log('put', 'DioException: ${e.type} - ${e.message}');
        if (_isRetryableError(e) && attempts <= _maxRetries) {
          _log('put', 'Retryable error, attempt $attempts/$_maxRetries. Retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        throw _handleDioError(e);
      }
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        final response = await _dio.delete(path, queryParameters: queryParameters);
        return _handleResponse(response);
      } on DioException catch (e) {
        attempts++;
        if (_isRetryableError(e) && attempts <= _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }
        throw _handleDioError(e);
      }
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    }
    return {'data': response.data};
  }

  ServerException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException();
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      
      // Try to get error from nested 'error' object first
      final errorData = data['error'] as Map<String, dynamic>?;
      
      // Handle validation errors array from backend
      final errors = data['errors'] as List<dynamic>?;
      String? validationMessage;
      if (errors != null && errors.isNotEmpty) {
        validationMessage = errors.join(', ');
      }
      
      // Get message from either errors array, error.message, data.message, or default
      final message = validationMessage ??
                      errorData?['message'] ?? 
                      data['message'] ?? 
                      'Something went wrong';
      
      // Get code from either error.code, or generate based on status
      final code = errorData?['code'] ?? 
                   _getCodeFromStatus(response.statusCode);
      
      return ServerException(
        code: code,
        message: message,
        statusCode: response.statusCode ?? 500,
        details: errorData?['details'] ?? errors,
      );
    }

    return ServerException(
      code: 'SERVER_ERROR',
      message: error.message ?? 'Something went wrong',
      statusCode: error.response?.statusCode ?? 500,
    );
  }
  
  String _getCodeFromStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'RATE_LIMITED';
      default:
        return 'SERVER_ERROR';
    }
  }

  /// Upload a file with multipart form data
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required dynamic file,
    String fileFieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    _log('uploadFile', 'POST $path (file upload)');
    
    int attempts = 0;
    while (true) {
      try {
        FormData formData;
        
        if (file is String) {
          // File path
          formData = FormData.fromMap({
            fileFieldName: await MultipartFile.fromFile(file),
            ...?additionalData,
          });
        } else {
          // Assume it's a File object
          formData = FormData.fromMap({
            fileFieldName: await MultipartFile.fromFile(file.path),
            ...?additionalData,
          });
        }

        final response = await _dio.post(
          path,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );
        _log('uploadFile', 'Response status: ${response.statusCode}');
        return _handleResponse(response);
      } on DioException catch (e) {
        attempts++;
        if (_isRetryableError(e) && attempts <= _maxRetries) {
          _log('uploadFile', 'Retryable error, attempt $attempts/$_maxRetries. Retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        _log('uploadFile', 'DioException: ${e.type} - ${e.message}');
        throw _handleDioError(e);
      }
    }
  }
}
