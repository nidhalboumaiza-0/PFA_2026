import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Global translation helper function
/// 
/// Usage:
/// ```dart
/// // Simple translation
/// Text(tr(context, 'login_screen.welcome_back'))
/// 
/// // Translation with arguments
/// Text(tr(context, 'greeting', args: {'name': 'John'}))
/// ```
String tr(BuildContext context, String key, {Map<String, String>? args}) {
  final localizations = AppLocalizations.of(context);
  if (localizations == null) {
    return key;
  }
  return localizations.translate(key, args: args);
}

/// Extension on BuildContext for easier access to translations
extension TranslationExtension on BuildContext {
  /// Translate a key
  /// 
  /// Usage:
  /// ```dart
  /// Text(context.tr('login_screen.welcome_back'))
  /// ```
  String tr(String key, {Map<String, String>? args}) {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      return key;
    }
    return localizations.translate(key, args: args);
  }

  /// Check if the current locale is RTL
  bool get isRTL {
    final localizations = AppLocalizations.of(this);
    return localizations?.isRTL ?? false;
  }

  /// Get the current locale
  Locale get currentLocale {
    final localizations = AppLocalizations.of(this);
    return localizations?.locale ?? const Locale('en');
  }
}

/// Extension on String for easier translation access when context is available
extension StringTranslation on String {
  /// Translate this string key using the provided context
  /// 
  /// Usage:
  /// ```dart
  /// Text('login_screen.welcome_back'.translate(context))
  /// ```
  String translate(BuildContext context, {Map<String, String>? args}) {
    return tr(context, this, args: args);
  }
}
