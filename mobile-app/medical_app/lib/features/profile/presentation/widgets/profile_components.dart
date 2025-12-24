import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

class ProfileInfoNote extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const ProfileInfoNote({
    super.key,
    required this.message,
    this.color = Colors.blue,
    this.icon = Icons.info_outline,
  });

  factory ProfileInfoNote.info(String message) {
    return ProfileInfoNote(
      message: message,
      color: Colors.blue,
      icon: Icons.info_outline,
    );
  }

  factory ProfileInfoNote.warning(String message) {
    return ProfileInfoNote(
      message: message,
      color: Colors.orange,
      icon: Icons.warning_amber_outlined,
    );
  }

  factory ProfileInfoNote.success(String message) {
    return ProfileInfoNote(
      message: message,
      color: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.raleway(
                fontSize: 13.sp,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatarHeader extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String subtitle;
  final VoidCallback? onEditPhoto;

  const ProfileAvatarHeader({
    super.key,
    this.imageUrl,
    required this.name,
    required this.subtitle,
    this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50.r,
                  backgroundColor: isDark ? const Color(0xFF2D2D44) : Colors.grey.shade100,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50.sp,
                          color: isDark ? Colors.white54 : Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              if (onEditPhoto != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Name
          Text(
            name,
            style: GoogleFonts.raleway(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4.h),
          // Subtitle (role/email)
          Text(
            subtitle,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePageTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const ProfilePageTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? AppColors.primaryColor;

    return Column(
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 50.sp,
            color: color,
          ),
        ),
        SizedBox(height: 16.h),
        // Title
        Text(
          title,
          style: GoogleFonts.raleway(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 8.h),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
        SizedBox(height: 24.h),
      ],
    );
  }
}

/// A reusable info tile for displaying label-value pairs
class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? leadingIcon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ProfileInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.leadingIcon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: leadingIcon != null
            ? Icon(
                leadingIcon,
                color: iconColor ?? AppColors.primaryColor,
                size: 22.sp,
              )
            : null,
        title: Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}

/// A row widget for displaying icon + text info
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: iconColor ?? (isDark ? Colors.white54 : Colors.grey.shade600),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: textStyle ??
                GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
          ),
        ),
      ],
    );
  }
}

/// A section header for profile pages
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20.sp,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.raleway(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A menu item for profile settings
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showArrow;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.showArrow = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.grey[800] : Colors.white),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryColor,
            size: 22.sp,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.raleway(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              )
            : null,
        trailing: trailing ??
            (showArrow
                ? Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  )
                : null),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      ),
    );
  }
}
