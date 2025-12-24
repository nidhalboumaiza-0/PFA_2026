import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';

class ProfileNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isLoading;

  const ProfileNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onPrevious,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = currentPage == totalPages - 1;
    final isFirstPage = currentPage == 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (!isFirstPage)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: Icon(Icons.arrow_back, size: 18.sp),
                label: Text(context.tr('previous')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          
          if (!isFirstPage) SizedBox(width: 12.w),

          // Next/Save button
          Expanded(
            flex: isFirstPage ? 1 : 1,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.6),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? context.tr('save_changes') : context.tr('next'),
                          style: GoogleFonts.raleway(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          isLastPage ? Icons.check : Icons.arrow_forward,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
