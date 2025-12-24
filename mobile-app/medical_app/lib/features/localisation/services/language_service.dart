import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String LANGUAGE_KEY = 'language_key';

  static Future<void> changeLocale(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_KEY, languageCode);
    
    Locale locale;
    switch (languageCode) {
      case 'fr':
        locale = const Locale('fr', 'FR');
        break;
      case 'ar':
        locale = const Locale('ar', 'AR');
        break;
      case 'en':
      default:
        locale = const Locale('en', 'US');
        break;
    }
    
    Get.updateLocale(locale);
  }

  static Future<Locale?> getSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString(LANGUAGE_KEY);
    
    if (languageCode == null) {
      return null;
    }
    
    switch (languageCode) {
      case 'fr':
        return const Locale('fr', 'FR');
      case 'ar':
        return const Locale('ar', 'AR');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
} 