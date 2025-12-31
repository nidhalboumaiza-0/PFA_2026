import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../signup_controller.dart';

class RoleSelectionStep extends StatelessWidget {
  final SignupController controller;
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  const RoleSelectionStep({
    super.key,
    required this.controller,
    required this.onContinue,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // Illustration
          Center(
            child: Image.asset(
              AppAssets.doctorsPanaImage,
              height: 180.h,
              width: 200.w,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 32.h),
          // Title
          Text(
            'Join E-Santé Today',
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: 8.h),
          Text(
            'Select how you want to use the app',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 32.h),
          // Role selector
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => RoleSelector(
              selectedRole: controller.data.role,
              onRoleSelected: controller.setRole,
            ),
          ),
          SizedBox(height: 40.h),
          // Continue button
          CustomButton(
            text: 'Continue',
            onPressed: onContinue,
          ),
          SizedBox(height: 24.h),
          // Sign in link
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.textSecondaryColor,
                ),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onSignIn,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
