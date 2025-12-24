import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isLoading;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      color: backgroundColor ?? theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.colorScheme.primary,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontSize: 15.sp,
              ),
            ),
            SizedBox(height: 8.h),
            // Value
            if (isLoading)
              SizedBox(
                height: 32.h,
                child: Center(
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              )
            else
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                  fontSize: 24.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
