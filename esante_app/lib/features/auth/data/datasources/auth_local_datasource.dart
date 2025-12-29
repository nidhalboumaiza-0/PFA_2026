import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<AuthTokensModel?> getCachedTokens();
  Future<void> clearTokens();

  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();

  Future<void> clearAll();
  Future<bool> hasTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keySessionId = 'session_id';
  static const String _keyUser = 'cached_user';

  Box<String> get _authBox => HiveStorageService.authBox;
  Box<String> get _userBox => HiveStorageService.userBox;

  void _log(String method, String message) {
    print('[AuthLocalDataSource.$method] $message');
  }

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    _log('cacheTokens', 'Caching tokens, sessionId: ${tokens.sessionId}');
    try {
      await _authBox.put(_keyAccessToken, tokens.accessToken);
      await _authBox.put(_keyRefreshToken, tokens.refreshToken);
      await _authBox.put(_keySessionId, tokens.sessionId);
      _log('cacheTokens', 'Tokens cached successfully');
      
      // Verify the save
      final savedAccessToken = _authBox.get(_keyAccessToken);
      _log('cacheTokens', 'Verification - accessToken saved: ${savedAccessToken != null}');
    } catch (e) {
      _log('cacheTokens', 'Error caching tokens: $e');
      throw CacheException(message: 'Failed to save authentication tokens: $e');
    }
  }

  @override
  Future<AuthTokensModel?> getCachedTokens() async {
    _log('getCachedTokens', 'Retrieving cached tokens...');
    try {
      final accessToken = _authBox.get(_keyAccessToken);
      final refreshToken = _authBox.get(_keyRefreshToken);
      final sessionId = _authBox.get(_keySessionId);

      _log('getCachedTokens', 'accessToken: ${accessToken != null ? "exists" : "null"}');
      _log('getCachedTokens', 'refreshToken: ${refreshToken != null ? "exists" : "null"}');
      _log('getCachedTokens', 'sessionId: ${sessionId ?? "null"}');

      if (accessToken == null || refreshToken == null || sessionId == null) {
        _log('getCachedTokens', 'One or more tokens missing, returning null');
        return null;
      }

      return AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
      );
    } catch (e) {
      _log('getCachedTokens', 'Error retrieving tokens: $e');
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    _log('clearTokens', 'Clearing all tokens...');
    try {
      await _authBox.delete(_keyAccessToken);
      await _authBox.delete(_keyRefreshToken);
      await _authBox.delete(_keySessionId);
      _log('clearTokens', 'Tokens cleared successfully');
    } catch (e) {
      _log('clearTokens', 'Error clearing tokens: $e');
      throw CacheException(message: 'Failed to clear authentication tokens: $e');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    _log('cacheUser', 'Caching user: ${user.email}');
    try {
      final userJson = jsonEncode(user.toJson());
      _log('cacheUser', 'User JSON length: ${userJson.length}');
      await _userBox.put(_keyUser, userJson);
      _log('cacheUser', 'User cached successfully');
      
      // Verify the save
      final savedUser = _userBox.get(_keyUser);
      _log('cacheUser', 'Verification - user saved: ${savedUser != null}');
    } catch (e) {
      _log('cacheUser', 'Error caching user: $e');
      throw CacheException(message: 'Failed to save user data: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    _log('getCachedUser', 'Retrieving cached user...');
    try {
      final userJson = _userBox.get(_keyUser);
      if (userJson == null) {
        _log('getCachedUser', 'No cached user found');
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      _log('getCachedUser', 'User retrieved: ${userMap['email']}');
      return UserModel.fromJson(userMap);
    } catch (e) {
      _log('getCachedUser', 'Error retrieving user: $e');
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    _log('clearUser', 'Clearing cached user...');
    try {
      await _userBox.delete(_keyUser);
      _log('clearUser', 'User cleared successfully');
    } catch (e) {
      _log('clearUser', 'Error clearing user: $e');
      throw CacheException(message: 'Failed to clear user data: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    _log('clearAll', 'Clearing all cached data...');
    await clearTokens();
    await clearUser();
    _log('clearAll', 'All data cleared');
  }

  @override
  Future<bool> hasTokens() async {
    final tokens = await getCachedTokens();
    final hasTokens = tokens != null;
    _log('hasTokens', 'Has tokens: $hasTokens');
    return hasTokens;
  }
}
