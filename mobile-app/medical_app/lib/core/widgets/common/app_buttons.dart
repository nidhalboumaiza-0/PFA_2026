import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

/// Animated back button with consistent styling across the app
/// Matches the design from authentication screens
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool showAnimation;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = GestureDetector(
      onTap: onPressed ?? () => Navigator.pop(context),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.sp,
          color: iconColor ?? AppColors.primaryColor,
        ),
      ),
    );

    if (showAnimation) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: child,
            );
          },
          child: button,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: button,
    );
  }
}

/// Primary action button with consistent styling
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = isLoading
        ? SizedBox(
            height: 20.h,
            width: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor ?? Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20.sp, color: textColor ?? Colors.white),
                SizedBox(width: 8.w),
              ],
              Text(
                text,
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
          disabledBackgroundColor: (backgroundColor ?? AppColors.primaryColor).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: buttonContent,
      ),
    );
  }
}

/// Secondary/outline button with consistent styling
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppColors.primaryColor;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 50.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20.sp, color: textColor ?? color),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button with consistent styling
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final bool isIconLeading;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.textColor,
    this.isIconLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.primaryColor;

    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && isIconLeading) ...[
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            text,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (icon != null && !isIconLeading) ...[
            SizedBox(width: 4.w),
            Icon(icon, size: 18.sp, color: color),
          ],
        ],
      ),
    );
  }
}

/// Icon button with background
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular((size / 2).r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular((size / 2).r),
          child: Icon(
            icon,
            size: (size * 0.5).sp,
            color: iconColor ?? AppColors.primaryColor,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Floating action button with consistent styling
class AppFloatingButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;

  const AppFloatingButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColors.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        icon: Icon(icon),
        label: Text(
          label!,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      child: Icon(icon),
    );
  }
}

/// Chip/Tag button
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (selectedColor ?? AppColors.primaryColor)
        : (unselectedColor ?? Colors.grey.shade200);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
