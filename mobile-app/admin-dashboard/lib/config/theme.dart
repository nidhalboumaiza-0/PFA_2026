import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2fa7bb);
  static const Color secondaryColor = Color(0xFF6c7ee1);
  static const Color accentColor = Color(0xFFf7a344);
  static const Color errorColor = Color(0xFFe74c3c);
  static const Color successColor = Color(0xFF2ecc71);

  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFF8FAFC);
  static const Color lightCardColor = Colors.white;
  static const Color lightTextColor = Color(0xFF1E293B);
  static const Color lightSecondaryTextColor = Color(0xFF64748B);

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF0F172A);
  static const Color darkCardColor = Color(0xFF1E293B);
  static const Color darkTextColor = Colors.white;
  static const Color darkSecondaryTextColor = Color(0xFFCBD5E1);

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: lightBackgroundColor,
    textTheme: _buildTextTheme().apply(
      bodyColor: lightTextColor,
      displayColor: lightTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: lightTextColor),
      titleTextStyle: TextStyle(
        color: lightTextColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      toolbarHeight: 56.h,
    ),
    cardTheme: CardTheme(
      color: lightCardColor,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(120.w, 48.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(120.w, 48.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      hintStyle: TextStyle(color: lightSecondaryTextColor, fontSize: 14.sp),
      labelStyle: TextStyle(color: lightTextColor, fontSize: 14.sp),
      errorStyle: TextStyle(color: errorColor, fontSize: 12.sp),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      labelStyle: TextStyle(fontSize: 12.sp, color: lightTextColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: _buildTextTheme().apply(
      bodyColor: darkTextColor,
      displayColor: darkTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCardColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: darkTextColor),
      titleTextStyle: TextStyle(
        color: darkTextColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      toolbarHeight: 56.h,
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(120.w, 48.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size(120.w, 48.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      hintStyle: TextStyle(color: darkSecondaryTextColor, fontSize: 14.sp),
      labelStyle: TextStyle(color: darkTextColor, fontSize: 14.sp),
      errorStyle: TextStyle(color: errorColor, fontSize: 12.sp),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      labelStyle: TextStyle(fontSize: 12.sp, color: darkTextColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    ),
  );
}
