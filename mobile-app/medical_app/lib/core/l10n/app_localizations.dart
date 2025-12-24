import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AppLocalizations class handles loading and retrieving translations
/// from JSON files based on the current locale.
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Static accessor for accessing the AppLocalizations instance
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Delegate for loading the localizations
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// List of supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  /// Loads the JSON file containing the translations for the current locale
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'lib/core/l10n/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
      return true;
    } catch (e) {
      debugPrint('Error loading locale ${locale.languageCode}: $e');
      // Fallback to English if the locale file is not found
      try {
        String jsonString = await rootBundle.loadString(
          'lib/core/l10n/en.json',
        );
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedStrings = jsonMap;
        return true;
      } catch (e) {
        debugPrint('Error loading fallback locale: $e');
        _localizedStrings = {};
        return false;
      }
    }
  }

  /// Translates a key with support for nested keys using dot notation
  /// Example: translate('login_screen.welcome_back')
  String translate(String key, {Map<String, String>? args}) {
    // Split the key by dots to support nested keys
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        // Return the key itself if translation is not found
        return key;
      }
    }

    if (value is! String) {
      return key;
    }

    String result = value;

    // Replace placeholders with arguments
    if (args != null) {
      args.forEach((argKey, argValue) {
        result = result.replaceAll('{$argKey}', argValue);
      });
    }

    return result;
  }

  /// Shorthand for translate
  String tr(String key, {Map<String, String>? args}) =>
      translate(key, args: args);

  /// Check if the current locale is RTL
  bool get isRTL => locale.languageCode == 'ar';
}

/// Delegate class for loading AppLocalizations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
