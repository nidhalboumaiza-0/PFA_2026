class ServerException implements Exception {
  final String? message;

  ServerException([this.message]);
}

class CacheException implements Exception {
  final String? message;

  CacheException([this.message]);
}

class OfflineException implements Exception {}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);
}

class UnauthorizedException implements Exception {}

class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);
}
