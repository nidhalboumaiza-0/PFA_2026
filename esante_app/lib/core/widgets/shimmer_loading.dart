import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// A reusable shimmer loading widget for profile screens
class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            // Profile Header Shimmer
            _buildProfileHeaderShimmer(context),
            SizedBox(height: 24.h),
            // Completion Progress Shimmer
            _buildProgressShimmer(context),
            SizedBox(height: 24.h),
            // Info Card Shimmer 1
            _buildInfoCardShimmer(context, 5),
            SizedBox(height: 16.h),
            // Info Card Shimmer 2
            _buildInfoCardShimmer(context, 3),
            SizedBox(height: 16.h),
            // Info Card Shimmer 3
            _buildInfoCardShimmer(context, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderShimmer(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 16.h),
        // Name
        Container(
          width: 200.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(height: 8.h),
        // Subtitle
        Container(
          width: 140.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressShimmer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150.w,
                  height: 14.h,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 8.h,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 20.h,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardShimmer(BuildContext context, int rowCount) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 150.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              const Spacer(),
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Info Rows
          ...List.generate(rowCount, (index) => Column(
            children: [
              if (index > 0) SizedBox(height: 12.h),
              _buildInfoRowShimmer(),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRowShimmer() {
    return Row(
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: Container(
            height: 14.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: Container(
            height: 14.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ],
    );
  }
}

/// A simpler shimmer loading for doctor profile
class DoctorProfileShimmerLoading extends StatelessWidget {
  const DoctorProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            // Profile Header
            _buildDoctorHeaderShimmer(),
            SizedBox(height: 24.h),
            // Completion bar
            _buildBarShimmer(),
            SizedBox(height: 24.h),
            // Professional Info
            _buildCardShimmer(7),
            SizedBox(height: 16.h),
            // Clinic Info
            _buildCardShimmer(3),
            SizedBox(height: 16.h),
            // About
            _buildCardShimmer(2),
            SizedBox(height: 16.h),
            // Working Hours
            _buildCardShimmer(4),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeaderShimmer() {
    return Column(
      children: [
        // Avatar with badge
        Stack(
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Doctor Name
        Container(
          width: 180.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(height: 8.h),
        // Specialty
        Container(
          width: 120.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(height: 8.h),
        // Rating
        Container(
          width: 100.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ],
    );
  }

  Widget _buildBarShimmer() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }

  Widget _buildCardShimmer(int rows) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 140.w,
                height: 18.h,
                color: Colors.grey[400],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Rows
          ...List.generate(rows, (i) => Padding(
            padding: EdgeInsets.only(top: i > 0 ? 10.h : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100.w,
                  height: 14.h,
                  color: Colors.grey[400],
                ),
                Container(
                  width: 80.w,
                  height: 14.h,
                  color: Colors.grey[400],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
