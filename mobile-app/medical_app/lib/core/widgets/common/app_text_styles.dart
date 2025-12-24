import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles using Google Fonts Raleway
/// Use these styles throughout the app for consistency
class AppTextStyles {
  AppTextStyles._();

  // ============== HEADINGS ==============
  
  /// Large heading - 24sp, bold
  static TextStyle heading1({Color? color}) => GoogleFonts.raleway(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: color ?? Colors.black87,
  );

  /// Medium heading - 20sp, bold
  static TextStyle heading2({Color? color}) => GoogleFonts.raleway(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: color ?? Colors.black87,
  );

  /// Small heading - 18sp, semi-bold
  static TextStyle heading3({Color? color}) => GoogleFonts.raleway(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.black87,
  );

  // ============== BODY TEXT ==============
  
  /// Large body text - 16sp, normal
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.raleway(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.black87,
  );

  /// Medium body text - 14sp, normal
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.black87,
  );

  /// Small body text - 12sp, normal
  static TextStyle bodySmall({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade600,
  );

  // ============== LABELS ==============
  
  /// Label text - 14sp, medium weight
  static TextStyle label({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.black87,
  );

  /// Small label text - 12sp, medium weight
  static TextStyle labelSmall({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.grey.shade700,
  );

  // ============== BUTTONS ==============
  
  /// Button text - 14sp, semi-bold
  static TextStyle button({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );

  /// Large button text - 16sp, semi-bold
  static TextStyle buttonLarge({Color? color}) => GoogleFonts.raleway(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );

  // ============== SPECIAL STYLES ==============
  
  /// Caption text - 11sp, normal (for timestamps, hints)
  static TextStyle caption({Color? color}) => GoogleFonts.raleway(
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade500,
  );

  /// Overline text - 10sp, medium (for labels above inputs)
  static TextStyle overline({Color? color}) => GoogleFonts.raleway(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: color ?? Colors.grey.shade600,
  );

  /// Hint text style - 14sp, for input hints
  static TextStyle hint({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade400,
  );

  /// Error text style - 12sp, red
  static TextStyle error({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.red.shade600,
  );

  /// Success text style - 12sp, green
  static TextStyle success({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.green.shade600,
  );

  // ============== APP BAR ==============
  
  /// AppBar title - 18sp, semi-bold
  static TextStyle appBarTitle({Color? color}) => GoogleFonts.raleway(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );

  /// AppBar subtitle - 12sp, normal
  static TextStyle appBarSubtitle({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.white70,
  );

  // ============== CARDS ==============
  
  /// Card title - 16sp, semi-bold
  static TextStyle cardTitle({Color? color}) => GoogleFonts.raleway(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.black87,
  );

  /// Card subtitle - 14sp, normal
  static TextStyle cardSubtitle({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade600,
  );

  /// Card description - 12sp, normal
  static TextStyle cardDescription({Color? color}) => GoogleFonts.raleway(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade500,
  );

  // ============== LINKS ==============
  
  /// Link text - 14sp, semi-bold, primary color
  static TextStyle link({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: color ?? const Color(0xFF1E88E5),
    decoration: TextDecoration.underline,
  );

  // ============== DIALOG ==============
  
  /// Dialog title - 18sp, bold
  static TextStyle dialogTitle({Color? color}) => GoogleFonts.raleway(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: color ?? Colors.black87,
  );

  /// Dialog content - 14sp, normal
  static TextStyle dialogContent({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.black87,
  );

  // ============== SECTION ==============
  
  /// Section header - 14sp, semi-bold, uppercase
  static TextStyle sectionHeader({Color? color}) => GoogleFonts.raleway(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color ?? Colors.grey.shade700,
  );

  // ============== NON-RESPONSIVE VERSIONS ==============
  // Use these when flutter_screenutil is not initialized
  
  /// Non-responsive body text
  static TextStyle bodyMediumFixed({Color? color}) => GoogleFonts.raleway(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.black87,
  );

  /// Non-responsive heading
  static TextStyle heading3Fixed({Color? color}) => GoogleFonts.raleway(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.black87,
  );

  /// Non-responsive caption
  static TextStyle captionFixed({Color? color}) => GoogleFonts.raleway(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color ?? Colors.grey.shade500,
  );
}

/// Extension on TextStyle for easy modification
extension TextStyleExtension on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  
  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  
  /// Make text italic
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  
  /// Add underline
  TextStyle get underlined => copyWith(decoration: TextDecoration.underline);
  
  /// Change color
  TextStyle withColor(Color color) => copyWith(color: color);
  
  /// Change size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}
