import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool enabled;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.raleway(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          enabled: enabled,
          validator: validator,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            color: enabled
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white38 : Colors.grey),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppColors.primaryColor.withOpacity(0.7),
                    size: 20.sp,
                  )
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileChipSelector extends StatelessWidget {
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const ProfileChipSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              option,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ProfileGenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onChanged;

  const ProfileGenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _buildGenderOption('Male', Icons.male, isDark),
        SizedBox(width: 12.w),
        _buildGenderOption('Female', Icons.female, isDark),
        SizedBox(width: 12.w),
        _buildGenderOption('Other', Icons.transgender, isDark),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isDark) {
    final isSelected = selectedGender == gender;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade600),
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                gender,
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
