import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

/// A reusable loading state widget
class LoadingStateWidget extends StatelessWidget {
  /// Optional loading message
  final String? message;

  /// Whether to use responsive sizing
  final bool useResponsiveSizing;

  /// Custom color for the indicator
  final Color? color;

  /// Size of the loading indicator
  final double indicatorSize;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.useResponsiveSizing = true,
    this.color,
    this.indicatorSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: useResponsiveSizing ? indicatorSize.w : indicatorSize,
            height: useResponsiveSizing ? indicatorSize.w : indicatorSize,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: useResponsiveSizing ? 16.h : 16),
            Text(
              message!,
              style: GoogleFonts.raleway(
                fontSize: useResponsiveSizing ? 14.sp : 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A shimmer loading placeholder for lists
class ShimmerLoadingWidget extends StatefulWidget {
  /// Number of shimmer items to show
  final int itemCount;
  
  /// Height of each shimmer item
  final double itemHeight;

  /// Whether items are cards or list tiles
  final bool isCard;

  const ShimmerLoadingWidget({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.isCard = true,
  });

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Container(
              height: widget.itemHeight.h,
              margin: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.isCard ? 12.r : 8.r),
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value, 0),
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    margin: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 12.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// A simple inline loading indicator
class InlineLoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const InlineLoadingWidget({
    super.key,
    this.message,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size.w,
          height: size.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
        if (message != null) ...[
          SizedBox(width: 12.w),
          Text(
            message!,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
