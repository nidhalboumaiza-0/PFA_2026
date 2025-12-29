import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../models/patient_profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<void> cacheProfile(PatientProfileModel profile);
  Future<PatientProfileModel?> getCachedProfile();
  Future<void> clearProfile();
  Future<bool> needsProfileCompletion();
  Future<void> setProfileCompletionShown([bool shown = true]);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _keyProfile = 'cached_profile';
  static const String _keyCompletionShown = 'profile_completion_shown';

  Box<String> get _userBox => HiveStorageService.userBox;

  void _log(String method, String message) {
    print('[ProfileLocalDataSource.$method] $message');
  }

  @override
  Future<void> cacheProfile(PatientProfileModel profile) async {
    _log('cacheProfile', 'Caching profile: ${profile.fullName}');
    try {
      final profileJson = jsonEncode(profile.toJson());
      await _userBox.put(_keyProfile, profileJson);
      _log('cacheProfile', 'Profile cached successfully');
    } catch (e) {
      _log('cacheProfile', 'Error caching profile: $e');
    }
  }

  @override
  Future<PatientProfileModel?> getCachedProfile() async {
    _log('getCachedProfile', 'Retrieving cached profile...');
    try {
      final profileJson = _userBox.get(_keyProfile);
      if (profileJson == null) {
        _log('getCachedProfile', 'No cached profile found');
        return null;
      }

      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      _log('getCachedProfile', 'Profile retrieved: ${profileMap['firstName']}');
      return PatientProfileModel.fromJson(profileMap);
    } catch (e) {
      _log('getCachedProfile', 'Error retrieving profile: $e');
      return null;
    }
  }

  @override
  Future<void> clearProfile() async {
    _log('clearProfile', 'Clearing cached profile...');
    try {
      await _userBox.delete(_keyProfile);
      await _userBox.delete(_keyCompletionShown);
      _log('clearProfile', 'Profile cleared successfully');
    } catch (e) {
      _log('clearProfile', 'Error clearing profile: $e');
    }
  }

  @override
  Future<bool> needsProfileCompletion() async {
    _log('needsProfileCompletion', 'Checking if profile completion needed...');
    try {
      final profile = await getCachedProfile();
      if (profile == null) {
        _log('needsProfileCompletion', 'No profile found, needs completion');
        return true;
      }
      
      final needsCompletion = !profile.isProfileComplete;
      _log('needsProfileCompletion', 'Needs completion: $needsCompletion');
      return needsCompletion;
    } catch (e) {
      _log('needsProfileCompletion', 'Error: $e');
      return true;
    }
  }

  @override
  Future<void> setProfileCompletionShown([bool shown = true]) async {
    _log('setProfileCompletionShown', 'Setting shown: $shown');
    await _userBox.put(_keyCompletionShown, shown.toString());
  }
}
