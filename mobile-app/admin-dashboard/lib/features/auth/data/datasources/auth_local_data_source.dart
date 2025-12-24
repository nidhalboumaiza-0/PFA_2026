import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedUser();
  Future<void> cacheUser(UserModel userToCache);
  Future<bool> hasUserCached();
  Future<void> clearCachedUser();
}

const CACHED_USER_KEY = 'CACHED_USER';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getCachedUser() {
    final jsonString = sharedPreferences.getString(CACHED_USER_KEY);
    if (jsonString != null) {
      return Future.value(UserModel.fromJson(json.decode(jsonString)));
    } else {
      throw CacheException('No user cached');
    }
  }

  @override
  Future<void> cacheUser(UserModel userToCache) {
    return sharedPreferences.setString(
      CACHED_USER_KEY,
      json.encode(userToCache.toJson()),
    );
  }

  @override
  Future<bool> hasUserCached() async {
    return sharedPreferences.containsKey(CACHED_USER_KEY);
  }

  @override
  Future<void> clearCachedUser() async {
    await sharedPreferences.remove(CACHED_USER_KEY);
  }
}
