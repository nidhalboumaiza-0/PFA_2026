import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

/// Beautiful widget displayed when there is no internet connection
class NoConnectionWidget extends StatelessWidget {
  /// Callback when retry button is pressed
  final VoidCallback? onRetry;
  
  /// Optional message to display
  final String? message;
  
  /// Whether to show compact version (for inline use)
  final bool compact;

  const NoConnectionWidget({
    super.key,
    this.onRetry,
    this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (compact) {
      return _buildCompactVersion(context, isDark);
    }
    
    return _buildFullVersion(context, isDark);
  }

  Widget _buildFullVersion(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    Positioned(
                      right: 25.w,
                      bottom: 25.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 24.sp,
                          color: Colors.orange[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
            
            // Title
            Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            
            // Message
            Text(
              message ?? 'Please check your WiFi or mobile data connection and try again.',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            
            // Retry button
            if (onRetry != null)
              CustomButton(
                text: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                width: 200.w,
              ),
            SizedBox(height: 16.h),
            
            // Tip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18.sp,
                    color: Colors.blue[600],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Tip: Try moving closer to your router',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactVersion(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Connection',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message ?? 'Check your internet connection',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
