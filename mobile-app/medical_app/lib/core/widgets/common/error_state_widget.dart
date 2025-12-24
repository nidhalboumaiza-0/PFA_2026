import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

/// A reusable error state widget for consistent error display
class ErrorStateWidget extends StatelessWidget {
  /// The error message to display
  final String message;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// Retry button text
  final String retryText;

  /// Whether to use responsive sizing
  final bool useResponsiveSizing;

  /// Custom icon
  final IconData icon;

  /// Icon color
  final Color? iconColor;

  /// Message color
  final Color? messageColor;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
    this.useResponsiveSizing = true,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(useResponsiveSizing ? 24.w : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: useResponsiveSizing ? 64.sp : 64,
              color: iconColor ?? Colors.red.shade300,
            ),
            SizedBox(height: useResponsiveSizing ? 16.h : 16),
            Text(
              message,
              style: GoogleFonts.raleway(
                fontSize: useResponsiveSizing ? 16.sp : 16,
                color: messageColor ?? Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: useResponsiveSizing ? 24.h : 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(useResponsiveSizing ? 24.r : 24),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: useResponsiveSizing ? 24.w : 24,
                    vertical: useResponsiveSizing ? 12.h : 12,
                  ),
                ),
                child: Text(
                  retryText,
                  style: GoogleFonts.raleway(
                    fontSize: useResponsiveSizing ? 14.sp : 14,
                    color: Colors.white,
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

/// A minimal error state for inline use
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 20.sp,
          color: Colors.red.shade400,
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            message,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: Colors.red.shade600,
            ),
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(width: 8.w),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
