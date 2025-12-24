import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String THEME_KEY = 'is_dark_mode';

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _isDarkMode);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryColor,
        secondary: AppColors.primaryColor,
        surface: Colors.grey[600]!,
        background: Colors.grey[900],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[800],
      ),
    )
        : ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.primaryColor,
        surface: Colors.white,
        background: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
      ),
    );
  }
}
