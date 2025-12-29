import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing Hive storage initialization and boxes
class HiveStorageService {
  static const String _authBoxName = 'auth_box';
  static const String _userBoxName = 'user_box';

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
