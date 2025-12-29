import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

/// A dialog that prompts users to complete their profile
class ProfileCompletionDialog extends StatelessWidget {
  final int completionPercentage;
  final VoidCallback onCompleteNow;
  final VoidCallback onLater;

  const ProfileCompletionDialog({
    super.key,
    required this.completionPercentage,
    required this.onCompleteNow,
    required this.onLater,
  });

  static Future<void> show(
    BuildContext context, {
    required int completionPercentage,
    required VoidCallback onCompleteNow,
    required VoidCallback onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileCompletionDialog(
        completionPercentage: completionPercentage,
        onCompleteNow: onCompleteNow,
        onLater: onLater,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface(context) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40.r,
              offset: Offset(0, 20.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            SizedBox(height: 20.h),
            _buildProgressIndicator(context),
            SizedBox(height: 24.h),
            _buildMessage(context),
            SizedBox(height: 28.h),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Lottie.asset(
            'assets/lottie/User floating.json',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Complete Your Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80.w,
              height: 80.h,
              child: CircularProgressIndicator(
                value: completionPercentage / 100,
                strokeWidth: 8.w,
                backgroundColor: AppColors.divider(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$completionPercentage%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(),
                  ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          _getProgressMessage(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(context),
              ),
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (completionPercentage >= 80) {
      return AppColors.success;
    } else if (completionPercentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.primary;
    }
  }

  String _getProgressMessage() {
    if (completionPercentage >= 80) {
      return 'Almost there! Just a few more details.';
    } else if (completionPercentage >= 50) {
      return 'Good progress! Keep going.';
    } else {
      return 'Let\'s get your profile set up!';
    }
  }

  Widget _buildMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 22.sp,
              color: AppColors.info,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'A complete profile helps doctors provide better care and makes appointments easier.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          text: 'Complete Now',
          icon: Icons.edit_rounded,
          onPressed: () {
            Navigator.pop(context);
            onCompleteNow();
          },
        ),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onLater();
          },
          style: TextButton.styleFrom(
            minimumSize: Size(double.infinity, 48.h),
          ),
          child: Text(
            'I\'ll do it later',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}
