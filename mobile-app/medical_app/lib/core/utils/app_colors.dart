import 'package:flutter/material.dart';

class AppColors {
  // Existing colors from ChatScreen
  static const primaryColor = Color(0xFF2fa7bb); // Matches provided primaryColor
  static const white = Color(0xFFFFFFFF); // Matches whiteColor
  static final greyLight = Colors.grey[200]!; // Used for input/received messages
  static const grey = Colors.grey; // Matches textSecondary
  static const black = Colors.black87; // Matches textPrimary
  // New colors from provided AppColors
  static const whiteColor = Color(0xFFFFFFFF); // Alias for white
  static const textPrimary = Colors.black87; // Alias for black
  static const textSecondary = Colors.grey; // Alias for grey
  static const divider = Color(0xFFE0E0E0); // New divider color
  static const iconColor = Color(0xff70bed5); // Matches provided primaryColor
}