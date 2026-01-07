import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

/// A beautiful error state widget with illustration and retry option
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? buttonText;
  final String? lottiePath;
  final String? imagePath;

  const ErrorStateWidget({
    super.key,
    this.title = 'Oops! Something went wrong',
    this.message,
    this.onRetry,
    this.buttonText = 'Try Again',
    this.lottiePath,
    this.imagePath,
  });

  /// Factory for connection errors
  factory ErrorStateWidget.connection({
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Connection Problem',
      message: 'Please check your internet connection and try again.',
      onRetry: onRetry,
      lottiePath: AppAssets.hospitalLottie,
    );
  }

  /// Factory for empty states
  factory ErrorStateWidget.empty({
    String title = 'Nothing here yet',
    String? message,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return ErrorStateWidget(
      title: title,
      message: message,
      onRetry: onAction,
      buttonText: actionText,
      imagePath: AppAssets.onlineDoctorPanaImage,
    );
  }

  /// Factory for appointment errors
  factory ErrorStateWidget.appointments({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      title: 'Unable to load appointments',
      message: message ?? 'We couldn\'t fetch your appointments. Please try again.',
      onRetry: onRetry,
      imagePath: AppAssets.doctorAmicoImage,
    );
  }

  /// Factory for general errors
  factory ErrorStateWidget.general({
    String? message,
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Something went wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      onRetry: onRetry,
      lottiePath: AppAssets.waitingAppointmentLottie,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            if (lottiePath != null)
              Lottie.asset(
                lottiePath!,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
              )
            else if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60.sp,
                  color: AppColors.error,
                ),
              ),
            
            SizedBox(height: 24.h),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (message != null) ...[
              SizedBox(height: 12.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (onRetry != null) ...[
              SizedBox(height: 32.h),
              SizedBox(
                width: 200.w,
                child: CustomButton(
                  text: buttonText ?? 'Try Again',
                  onPressed: onRetry!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
