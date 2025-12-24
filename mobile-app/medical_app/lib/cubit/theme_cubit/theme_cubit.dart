import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// States
abstract class ThemeState {}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;
  
  ThemeLoaded(this.themeMode);
}

// Cubit
class ThemeCubit extends Cubit<ThemeState> {
  static const String THEME_KEY = 'app_theme_mode';
  
  ThemeCubit() : super(ThemeInitial()) {
    _loadTheme();
  }
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(THEME_KEY);
    
    if (savedTheme != null) {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    
    emit(ThemeLoaded(_themeMode));
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME_KEY, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    
    emit(ThemeLoaded(_themeMode));
  }

  // Directly set theme mode
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME_KEY, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    
    emit(ThemeLoaded(_themeMode));
  }
} 