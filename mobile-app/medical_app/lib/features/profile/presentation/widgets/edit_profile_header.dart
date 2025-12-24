import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';

class EditProfileHeader extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final List<String> stepLabels;
  final VoidCallback onBack;
  final bool hasChanges;
  final VoidCallback onSave;

  const EditProfileHeader({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.stepLabels,
    required this.onBack,
    required this.hasChanges,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Back button, title and save button
          Row(
            children: [
              AppBackButton(
                onPressed: onBack,
                showAnimation: false,
              ),
              Expanded(
                child: Text(
                  context.tr('edit_profile'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildSaveButton(isDark),
            ],
          ),
          SizedBox(height: 20.h),
          // Progress indicator
          _buildProgressIndicator(isDark),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return GestureDetector(
      onTap: hasChanges ? onSave : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: hasChanges
              ? AppColors.primaryColor
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: hasChanges && !isDark
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          Icons.check,
          size: 18.sp,
          color: hasChanges
              ? Colors.white
              : (isDark ? Colors.white38 : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      children: List.generate(totalPages * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: currentPage > stepIndex
                  ? AppColors.primaryColor
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          );
        } else {
          // Step indicator
          final stepIndex = index ~/ 2;
          return _buildStepIndicator(stepIndex, stepLabels[stepIndex], isDark);
        }
      }),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isDark) {
    final isActive = currentPage >= step;
    final isCurrent = currentPage == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryColor
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3), width: 3)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.raleway(
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 10.sp,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? AppColors.primaryColor
                : (isDark ? Colors.white54 : Colors.grey),
          ),
        ),
      ],
    );
  }
}
