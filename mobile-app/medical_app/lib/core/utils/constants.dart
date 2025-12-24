import 'package:flutter/material.dart';

// App Colors
const Color kPrimaryColor = Color(0xFF1976D2);
const Color kSecondaryColor = Color(0xFF03A9F4);
const Color kAccentColor = Color(0xFF64B5F6);
const Color kErrorColor = Color(0xFFE57373);
const Color kSuccessColor = Color(0xFF81C784);
const Color kWarningColor = Color(0xFFFFB74D);
const Color kInfoColor = Color(0xFF4FC3F7);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF212121);
const Color kTextLightColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFBDBDBD);

// API URLs
const String kBaseUrl = 'http://192.168.1.204:3000';
const String kSocketUrl = 'http://192.168.1.204:3006'; // Direct to messaging-service for WebSocket

// Shared Preferences Keys
const String kTokenKey = 'TOKEN'; // Must match auth_local_data_source.dart
const String kUserIdKey = 'userId';
const String kUserRoleKey = 'userRole';
const String kUserNameKey = 'userName';
const String kUserEmailKey = 'userEmail';
const String kUserPhotoKey = 'userPhoto';
const String kIsLoggedInKey = 'isLoggedIn';
const String kIsOnboardingCompleteKey = 'isOnboardingComplete';
const String kThemeModeKey = 'themeMode';
const String kLocaleKey = 'locale';
const String kNotificationEnabledKey = 'notificationEnabled';

// Animation Durations
const Duration kAnimationDuration = Duration(milliseconds: 300);
const Duration kSnackBarDuration = Duration(seconds: 3);
const Duration kDialogTransitionDuration = Duration(milliseconds: 250);
const Duration kPageTransitionDuration = Duration(milliseconds: 300);
const Duration kButtonAnimationDuration = Duration(milliseconds: 200);
const Duration kSplashScreenDuration = Duration(seconds: 2);

// Sizes
const double kDefaultPadding = 16.0;
const double kDefaultBorderRadius = 8.0;
const double kDefaultButtonHeight = 48.0;
const double kDefaultIconSize = 24.0;
const double kDefaultFontSize = 14.0;
const double kDefaultHeaderFontSize = 18.0;
const double kDefaultTitleFontSize = 16.0;
const double kDefaultSubtitleFontSize = 14.0;
const double kDefaultBodyFontSize = 14.0;
const double kDefaultCaptionFontSize = 12.0;
const double kDefaultButtonFontSize = 14.0;
