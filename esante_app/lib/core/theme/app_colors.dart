import 'package:flutter/material.dart';

/// App color scheme that supports light and dark mode
class AppColors {
  AppColors._();

  // ============== Brand Colors ==============
  static const Color primary = Color(0xFF2CA6FF);
  static const Color primaryLight = Color(0xFF6BC4FF);
  static const Color primaryDark = Color(0xFF0077CC);

  // ============== Semantic Colors ==============
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ============== Static Fallback Colors (for const contexts) ==============
  /// Use these only in const contexts where BuildContext is not available
  static const Color textPrimaryStatic = Color(0xFF111827);
  static const Color textSecondaryStatic = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);

  // ============== Gradients ==============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2CA6FF), Color(0xFF0077CC)],
  );

  // ============== Light Theme Colors ==============
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightDivider = Color(0xFFE5E7EB);
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightTextHint = Color(0xFF9CA3AF);
  static const Color _lightInputFill = Color(0xFFF3F4F6);
  static const Color _lightInputBorder = Color(0xFFE5E7EB);
  static const Color _lightShadow = Color(0x1A000000);

  // ============== Dark Theme Colors ==============
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _darkDivider = Color(0xFF334155);
  static const Color _darkTextPrimary = Color(0xFFF9FAFB);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkTextHint = Color(0xFF6B7280);
  static const Color _darkInputFill = Color(0xFF1E293B);
  static const Color _darkInputBorder = Color(0xFF334155);
  static const Color _darkShadow = Color(0x40000000);

  // ============== Color Scheme Getters ==============
  
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBackground
          : _lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkSurface
          : _lightSurface;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkCard
          : _lightCard;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkDivider
          : _lightDivider;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextPrimary
          : _lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextSecondary
          : _lightTextSecondary;

  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextHint
          : _lightTextHint;

  static Color inputFill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkInputFill
          : _lightInputFill;

  static Color inputBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkInputBorder
          : _lightInputBorder;

  static Color shadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkShadow
          : _lightShadow;

  static LinearGradient backgroundGradient(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFE8F4FD)],
            );

  // ============== Utility Methods ==============
  
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

/// Extension for easier color access from BuildContext
extension AppColorsExtension on BuildContext {
  Color get backgroundColor => AppColors.background(this);
  Color get surfaceColor => AppColors.surface(this);
  Color get cardColor => AppColors.card(this);
  Color get dividerColor => AppColors.divider(this);
  Color get textPrimaryColor => AppColors.textPrimary(this);
  Color get textSecondaryColor => AppColors.textSecondary(this);
  Color get textHintColor => AppColors.textHint(this);
  Color get inputFillColor => AppColors.inputFill(this);
  Color get inputBorderColor => AppColors.inputBorder(this);
  Color get shadowColor => AppColors.shadow(this);
  bool get isDarkMode => AppColors.isDark(this);
}
