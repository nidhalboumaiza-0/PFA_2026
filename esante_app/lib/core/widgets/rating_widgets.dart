import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';
import 'app_text.dart';

/// A reusable star rating widget
class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;
  final MainAxisAlignment alignment;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 24,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.interactive = false,
    this.onRatingChanged,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: List.generate(starCount, (index) {
        final isFilled = index < rating;
        final isHalfFilled = index < rating && index + 1 > rating;

        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!(index + 1.0)
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Icon(
              isHalfFilled
                  ? Icons.star_half
                  : isFilled
                      ? Icons.star
                      : Icons.star_border,
              size: size.sp,
              color: isFilled || isHalfFilled ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

/// A compact rating display with number
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool showCount;
  final double size;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.showCount = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: size.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        if (showCount && reviewCount != null) ...[
          SizedBox(width: 4.w),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: (size - 2).sp,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Rating dialog for submitting reviews
class RatingDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? doctorName;
  final bool isLoading;
  final Future<void> Function(int rating, String? comment)? onSubmit;

  const RatingDialog({
    super.key,
    this.title = 'Rate Your Experience',
    this.subtitle,
    this.doctorName,
    this.isLoading = false,
    this.onSubmit,
  });

  /// Show the rating dialog
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String title = 'Rate Your Experience',
    String? subtitle,
    String? doctorName,
    Future<void> Function(int rating, String? comment)? onSubmit,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        title: title,
        subtitle: subtitle,
        doctorName: doctorName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent 🌟';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      if (widget.onSubmit != null) {
        final comment = _commentController.text.trim();
        await widget.onSubmit!(_rating, comment.isEmpty ? null : comment);
      }
      if (mounted) {
        Navigator.pop(context, {
          'rating': _rating,
          'comment': _commentController.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              width: 64.w,
              height: 64.h,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 36.sp,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            AppTitle(
              text: widget.title,
              fontSize: 20.sp,
            ),
            SizedBox(height: 8.h),

            // Subtitle
            if (widget.doctorName != null)
              AppSubtitle(
                text: 'How was your appointment with Dr. ${widget.doctorName}?',
                fontSize: 14.sp,
              )
            else if (widget.subtitle != null)
              AppSubtitle(
                text: widget.subtitle!,
                fontSize: 14.sp,
              ),

            SizedBox(height: 24.h),

            // Star Rating
            StarRating(
              rating: _rating.toDouble(),
              size: 40,
              interactive: !_isSubmitting,
              alignment: MainAxisAlignment.center,
              onRatingChanged: (value) => setState(() => _rating = value.toInt()),
            ),
            SizedBox(height: 8.h),

            // Rating Label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabel,
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Comment Field
            CustomTextField(
              controller: _commentController,
              hintText: 'Share your experience (optional)',
              maxLines: 3,
              enabled: !_isSubmitting,
            ),

            SizedBox(height: 24.h),

            // Actions
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    isOutlined: true,
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: 'Submit',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
