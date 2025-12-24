import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

/// A styled text field widget for consistent input styling across the app
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isDark = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = isDark || Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: darkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            maxLines: maxLines,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            focusNode: focusNode,
            autofocus: autofocus,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: darkMode ? Colors.white : Colors.black87,
            ),
            decoration: _buildDecoration(darkMode),
            validator: validator,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildDecoration(bool darkMode) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.raleway(
        fontSize: 14.sp,
        color: darkMode ? Colors.white38 : Colors.grey.shade400,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20.sp),
      ),
      filled: true,
      fillColor: darkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: darkMode ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: darkMode ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
    );
  }
}

/// A styled password field with visibility toggle
class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isDark = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    final darkMode = widget.isDark || Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: darkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _isObscure,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            focusNode: widget.focusNode,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: darkMode ? Colors.white : Colors.black87,
            ),
            decoration: _buildDecoration(darkMode),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildDecoration(bool darkMode) {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: GoogleFonts.raleway(
        fontSize: 14.sp,
        color: darkMode ? Colors.white38 : Colors.grey.shade400,
      ),
      prefixIcon: Container(
        margin: EdgeInsets.all(10.r),
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 20.sp),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: darkMode ? Colors.white54 : Colors.grey.shade600,
          size: 22.sp,
        ),
        onPressed: () => setState(() => _isObscure = !_isObscure),
      ),
      filled: true,
      fillColor: darkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: darkMode ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

/// A styled phone number field using intl_phone_field styling
class AppPhoneField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isDark;
  final void Function(String completeNumber, bool isValid)? onChanged;
  final String? Function(String?)? validator;
  final String initialCountryCode;

  const AppPhoneField({
    super.key,
    required this.label,
    required this.hint,
    this.isDark = false,
    this.onChanged,
    this.validator,
    this.initialCountryCode = 'TN',
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = isDark || Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: darkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: darkMode ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: darkMode ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Text(
                hint,
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: darkMode ? Colors.white38 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A styled date picker field
class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  const AppDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onTap,
    this.isDark = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = isDark || Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: darkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: darkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: darkMode ? Colors.white38 : Colors.grey.shade400,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(10.r),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.calendar_today_outlined, color: AppColors.primaryColor, size: 20.sp),
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: darkMode ? Colors.white54 : Colors.grey.shade600,
              ),
              filled: true,
              fillColor: darkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: darkMode ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
