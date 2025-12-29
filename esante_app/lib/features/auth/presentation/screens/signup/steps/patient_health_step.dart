import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../signup_controller.dart';

class PatientHealthStep extends StatefulWidget {
  final SignupController controller;
  final VoidCallback onContinue;

  const PatientHealthStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  @override
  State<PatientHealthStep> createState() => _PatientHealthStepState();
}

class _PatientHealthStepState extends State<PatientHealthStep> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.controller.data;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optional health information helps doctors provide better care',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 24.h),
          BloodTypeDropdown(
            value: data.bloodType,
            onChanged: (value) {
              setState(() {
                data.bloodType = value;
              });
            },
          ),
          SizedBox(height: 24.h),
          // Info card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'You can add allergies, chronic diseases, and emergency contacts later in your profile settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40.h),
          CustomButton(
            text: 'Continue',
            onPressed: widget.onContinue,
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
