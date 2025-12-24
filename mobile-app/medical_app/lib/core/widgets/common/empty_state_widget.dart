import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// A reusable empty state widget with Lottie animation
/// Use this widget when a list or content area is empty
class EmptyStateWidget extends StatelessWidget {
  /// The main message to display
  final String message;

  /// Optional description below the message
  final String? description;

  /// Optional Lottie animation path (defaults to empty.json)
  final String animationPath;

  /// Size of the animation
  final double animationSize;

  /// Optional action button text
  final String? actionText;

  /// Optional action button callback
  final VoidCallback? onAction;

  /// Whether to use responsive sizing
  final bool useResponsiveSizing;

  /// Custom message text style
  final TextStyle? messageStyle;

  /// Custom description text style
  final TextStyle? descriptionStyle;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.description,
    this.animationPath = 'assets/lotties/empty.json',
    this.animationSize = 200,
    this.actionText,
    this.onAction,
    this.useResponsiveSizing = true,
    this.messageStyle,
    this.descriptionStyle,
  });

  @override
  Widget build(BuildContext context) {
    final size = useResponsiveSizing ? animationSize.w : animationSize;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(useResponsiveSizing ? 24.w : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Lottie.asset(
                animationPath,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: useResponsiveSizing ? 16.h : 16),
            Text(
              message,
              style: messageStyle ?? GoogleFonts.raleway(
                fontSize: useResponsiveSizing ? 18.sp : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              SizedBox(height: useResponsiveSizing ? 8.h : 8),
              Text(
                description!,
                style: descriptionStyle ?? GoogleFonts.raleway(
                  fontSize: useResponsiveSizing ? 14.sp : 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              SizedBox(height: useResponsiveSizing ? 24.h : 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(useResponsiveSizing ? 24.r : 24),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: useResponsiveSizing ? 24.w : 24,
                    vertical: useResponsiveSizing ? 12.h : 12,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: GoogleFonts.raleway(
                    fontSize: useResponsiveSizing ? 14.sp : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact version of the empty state for smaller spaces
class CompactEmptyStateWidget extends StatelessWidget {
  final String message;
  final double animationSize;
  final bool useResponsiveSizing;

  const CompactEmptyStateWidget({
    super.key,
    required this.message,
    this.animationSize = 150,
    this.useResponsiveSizing = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = useResponsiveSizing ? animationSize.w : animationSize;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/lotties/empty.json',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: useResponsiveSizing ? 8.h : 8),
          Text(
            message,
            style: GoogleFonts.raleway(
              fontSize: useResponsiveSizing ? 14.sp : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
