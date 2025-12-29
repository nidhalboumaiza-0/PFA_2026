import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final String dateFormat;
  final IconData? prefixIcon;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.dateFormat = 'MMM dd, yyyy',
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = selectedDate != null
        ? DateFormat(dateFormat).format(selectedDate!)
        : hintText ?? 'Select date';

    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: RichText(
              text: TextSpan(
                text: label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.textPrimaryColor,
                ),
                children: isRequired
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        // Date picker field
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : selectedDate != null
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : context.inputBorderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    color: selectedDate != null
                        ? AppColors.primary
                        : context.textSecondaryColor,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: selectedDate != null
                          ? context.textPrimaryColor
                          : context.textSecondaryColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: selectedDate != null
                      ? AppColors.primary
                      : context.textSecondaryColor,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
        // Error text
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? now;
    final initial = selectedDate ?? DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: context.surfaceColor,
                    onSurface: context.textPrimaryColor,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: context.surfaceColor,
                    onSurface: context.textPrimaryColor,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}

/// A date picker specifically for Date of Birth
class DateOfBirthPicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;
  final int minAge;
  final int maxAge;

  const DateOfBirthPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.errorText,
    this.minAge = 0,
    this.maxAge = 120,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return CustomDatePicker(
      label: 'Date of Birth',
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      firstDate: DateTime(now.year - maxAge),
      lastDate: DateTime(now.year - minAge, now.month, now.day),
      hintText: 'Select your date of birth',
      errorText: errorText,
      isRequired: true,
      prefixIcon: Icons.cake_outlined,
    );
  }
}
