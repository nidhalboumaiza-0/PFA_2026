import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

enum UserRoleOption { patient, doctor }

class RoleSelectionCard extends StatelessWidget {
  final UserRoleOption role;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleSelectionCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPatient = role == UserRoleOption.patient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.inputBorderColor,
            width: isSelected ? 2.w : 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ]
              : [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.primaryGradient
                    : LinearGradient(
                        colors: isDark 
                            ? [Colors.grey.shade800, Colors.grey.shade700]
                            : [Colors.grey.shade100, Colors.grey.shade50],
                      ),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isPatient ? Icons.person_rounded : Icons.medical_services_rounded,
                size: 40.sp,
                color: isSelected ? Colors.white : context.textSecondaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            Text(
              isPatient ? 'Patient' : 'Doctor',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : context.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            // Description
            Text(
              isPatient
                  ? 'Book appointments and\nmanage your health'
                  : 'Manage patients and\nappointments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textSecondaryColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.dividerColor,
                  width: 2.w,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16.sp,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  final UserRoleOption? selectedRole;
  final ValueChanged<UserRoleOption> onRoleSelected;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoleSelectionCard(
            role: UserRoleOption.patient,
            isSelected: selectedRole == UserRoleOption.patient,
            onTap: () => onRoleSelected(UserRoleOption.patient),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: RoleSelectionCard(
            role: UserRoleOption.doctor,
            isSelected: selectedRole == UserRoleOption.doctor,
            onTap: () => onRoleSelected(UserRoleOption.doctor),
          ),
        ),
      ],
    );
  }
}
