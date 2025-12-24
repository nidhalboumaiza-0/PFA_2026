import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/medecin_model.dart';

abstract class AuthLocalDataSource {
  /// Caches the user data locally.
  Future<Unit> cacheUser(UserModel user);

  /// Retrieves the cached user data.
  Future<UserModel> getUser();

  /// Clears cached user data and token (signs out locally).
  Future<Unit> signOut();

  /// Saves the authentication token.
  Future<Unit> saveToken(String token);

  /// Retrieves the authentication token.
  Future<String?> getToken();

  /// Saves the refresh token.
  Future<Unit> saveRefreshToken(String refreshToken);

  /// Retrieves the refresh token.
  Future<String?> getRefreshToken();

  /// Clears the authentication token.
  Future<Unit> clearToken();

  /// Clears the refresh token.
  Future<Unit> clearRefreshToken();

  /// Clears cached user data.
  Future<Unit> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String USER_KEY = 'CACHED_USER';
  static const String TOKEN_KEY = 'TOKEN';
  static const String REFRESH_TOKEN_KEY = 'REFRESH_TOKEN';

  @override
  Future<Unit> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await sharedPreferences.setString(USER_KEY, userJson);
    return unit;
  }

  @override
  Future<UserModel> getUser() async {
    final userJson = sharedPreferences.getString(USER_KEY);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        if (userMap.containsKey('antecedent')) {
          return PatientModel.fromJson(userMap);
        } else if (userMap.containsKey('speciality') && userMap.containsKey('numLicence')) {
          return MedecinModel.fromJson(userMap);
        } else {
          return UserModel.fromJson(userMap);
        }
      } catch (e) {
        throw EmptyCacheException(message: 'Failed to parse cached user data: $e');
      }
    } else {
      throw EmptyCacheException(message: 'No cached user data found');
    }
  }

  @override
  Future<Unit> signOut() async {
    await sharedPreferences.remove(USER_KEY);
    await sharedPreferences.remove(TOKEN_KEY);
    await sharedPreferences.remove(REFRESH_TOKEN_KEY);
    return unit;
  }

  @override
  Future<Unit> saveToken(String token) async {
    await sharedPreferences.setString(TOKEN_KEY, token);
    return unit;
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(TOKEN_KEY);
  }

  @override
  Future<Unit> saveRefreshToken(String refreshToken) async {
    await sharedPreferences.setString(REFRESH_TOKEN_KEY, refreshToken);
    return unit;
  }

  @override
  Future<String?> getRefreshToken() async {
    return sharedPreferences.getString(REFRESH_TOKEN_KEY);
  }

  @override
  Future<Unit> clearToken() async {
    await sharedPreferences.remove(TOKEN_KEY);
    return unit;
  }

  @override
  Future<Unit> clearRefreshToken() async {
    await sharedPreferences.remove(REFRESH_TOKEN_KEY);
    return unit;
  }

  @override
  Future<Unit> clearCachedUser() async {
    await sharedPreferences.remove(USER_KEY);
    return unit;
  }
}