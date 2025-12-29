import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required Dio dio}) : _dio = dio;

  void _log(String method, String message) {
    print('[ApiClient.$method] $message');
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _log('get', 'GET $path');
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      _log('get', 'Response status: ${response.statusCode}');
      return _handleResponse(response);
    } on DioException catch (e) {
      _log('get', 'DioException: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    _log('post', 'POST $path');
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      _log('post', 'Response status: ${response.statusCode}');
      return _handleResponse(response);
    } on DioException catch (e) {
      _log('post', 'DioException: ${e.type} - ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
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
      
      // Get message from either error.message, data.message, or default
      final message = errorData?['message'] ?? 
                      data['message'] ?? 
                      'Something went wrong';
      
      // Get code from either error.code, or generate based on status
      final code = errorData?['code'] ?? 
                   _getCodeFromStatus(response.statusCode);
      
      return ServerException(
        code: code,
        message: message,
        statusCode: response.statusCode ?? 500,
        details: errorData?['details'],
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
}
