import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

/// A reusable card widget for displaying grouped information
class InfoCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<InfoItem>? items;
  final List<Widget>? children;
  final Widget? trailing;
  final VoidCallback? onEdit;
  final EdgeInsets? padding;
  final bool showDividers;

  const InfoCard({
    super.key,
    required this.title,
    this.icon,
    this.items,
    this.children,
    this.trailing,
    this.onEdit,
    this.padding,
    this.showDividers = true,
  }) : assert(items != null || children != null, 'Either items or children must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface(context) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : AppColors.shadow(context).withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          // Use children if provided, otherwise use items
          if (children != null)
            Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children!,
              ),
            )
          else if (items != null)
            ...items!.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (showDividers && index > 0)
                    Divider(
                      height: 1.h,
                      indent: 56.w,
                      color: AppColors.divider(context),
                    ),
                  _buildInfoItem(context, item),
                ],
              );
            }),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, InfoItem item) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36.w,
            child: Icon(
              item.icon,
              size: 20.sp,
              color: AppColors.textHint(context),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                ),
                SizedBox(height: 2.h),
                if (item.child != null)
                  item.child!
                else
                  Text(
                    item.value ?? 'Not set',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: item.value != null
                              ? AppColors.textPrimary(context)
                              : AppColors.textHint(context),
                          fontStyle:
                              item.value == null ? FontStyle.italic : null,
                        ),
                  ),
              ],
            ),
          ),
          if (item.trailing != null) item.trailing!,
        ],
      ),
    );
  }
}

/// Represents a single info item within an InfoCard
class InfoItem {
  final String label;
  final String? value;
  final IconData icon;
  final Widget? child;
  final Widget? trailing;

  const InfoItem({
    required this.label,
    this.value,
    required this.icon,
    this.child,
    this.trailing,
  });
}

/// A simple row widget for displaying label-value pairs
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20.sp,
              color: AppColors.textHint(context),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: labelStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle ?? Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}


