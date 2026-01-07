import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing Hive storage initialization and boxes
class HiveStorageService {
  static const String _authBoxName = 'auth_box';
  static const String _userBoxName = 'user_box';
  static const String _keyUser = 'cached_user';
  static const String _keyAccessToken = 'access_token';

  static Box<String>? _authBox;
  static Box<String>? _userBox;

  /// Initialize Hive and open required boxes
  static Future<void> init() async {
    print('[HiveStorageService.init] Initializing Hive...');
    await Hive.initFlutter();
    
    print('[HiveStorageService.init] Opening auth box...');
    _authBox = await Hive.openBox<String>(_authBoxName);
    
    print('[HiveStorageService.init] Opening user box...');
    _userBox = await Hive.openBox<String>(_userBoxName);
    
    print('[HiveStorageService.init] Hive initialized successfully');
  }

  /// Get the auth box for token storage
  static Box<String> get authBox {
    if (_authBox == null || !_authBox!.isOpen) {
      throw Exception('Auth box is not initialized. Call HiveStorageService.init() first.');
    }
    return _authBox!;
  }

  /// Get the user box for user data storage
  static Box<String> get userBox {
    if (_userBox == null || !_userBox!.isOpen) {
      throw Exception('User box is not initialized. Call HiveStorageService.init() first.');
    }
    return _userBox!;
  }

  /// Get the current logged-in user's ID
  static String? getCurrentUserId() {
    try {
      // First try to get profileId from JWT token (this is what messages use)
      final profileId = getProfileIdFromToken();
      if (profileId != null) {
        return profileId;
      }
      
      // Fallback to cached user id
      final userJson = _userBox?.get(_keyUser);
      if (userJson == null) return null;
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return userMap['id'] as String?;
    } catch (e) {
      print('[HiveStorageService.getCurrentUserId] Error: $e');
      return null;
    }
  }

  /// Get profileId from the JWT access token
  /// Messages use profileId as senderId, not userId
  static String? getProfileIdFromToken() {
    try {
      final token = _authBox?.get(_keyAccessToken);
      if (token == null) return null;
      
      // Decode JWT (format: header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (middle part)
      String payload = parts[1];
      // Add padding if needed for base64 decoding
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      
      // Return profileId - this is what the messaging service uses
      final profileId = payloadMap['profileId'] as String?;
      print('[HiveStorageService.getProfileIdFromToken] profileId: $profileId');
      return profileId;
    } catch (e) {
      print('[HiveStorageService.getProfileIdFromToken] Error: $e');
      return null;
    }
  }

  /// Close all boxes
  static Future<void> close() async {
    await _authBox?.close();
    await _userBox?.close();
  }

  /// Clear all data (for logout)
  static Future<void> clearAll() async {
    await _authBox?.clear();
    await _userBox?.clear();
  }
}
