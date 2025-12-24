import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/constants.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthLocalDataSource _localDataSource;
  bool _isRefreshing = false;

  AuthenticatedHttpClient(this._inner, this._localDataSource);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add token to request if available
    final token = await _localDataSource.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Send request
    final response = await _inner.send(request);

    // Check for 401 Unauthorized
    if (response.statusCode == 401 && !_isRefreshing) {
      // Try to refresh token
      _isRefreshing = true;
      try {
        final refreshToken = await _localDataSource.getRefreshToken();
        if (refreshToken != null) {
          final refreshResponse = await _inner.post(
            Uri.parse(AppConstants.refreshTokenEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          );

          if (refreshResponse.statusCode == 200) {
            final data = jsonDecode(refreshResponse.body);
            final newToken = data['accessToken'];
            await _localDataSource.saveToken(newToken);
            
            // Retry original request with new token
            final newRequest = _copyRequest(request);
            newRequest.headers['Authorization'] = 'Bearer $newToken';
            _isRefreshing = false;
            return await _inner.send(newRequest);
          }
        }
      } catch (e) {
        // Refresh failed
      } finally {
        _isRefreshing = false;
      }
    }

    return response;
  }

  // Helper to copy request for retry
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('StreamedRequest cannot be retried');
    } else {
      throw Exception('Unknown request type');
    }

    requestCopy.headers.addAll(request.headers);
    requestCopy.followRedirects = request.followRedirects;
    requestCopy.maxRedirects = request.maxRedirects;
    requestCopy.persistentConnection = request.persistentConnection;

    return requestCopy;
  }
}
