import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';

/// A modern rating dialog widget for rating doctors after appointments
class RatingDialog extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String appointmentId;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.appointmentId,
    this.onRatingSubmitted,
  });

  /// Shows the rating dialog
  static Future<bool?> show({
    required BuildContext context,
    required String doctorId,
    required String doctorName,
    required String patientId,
    required String appointmentId,
    VoidCallback? onRatingSubmitted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        doctorId: doctorId,
        doctorName: doctorName,
        patientId: patientId,
        appointmentId: appointmentId,
        onRatingSubmitted: onRatingSubmitted,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog>
    with SingleTickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getRatingText(BuildContext context) {
    if (_rating == 0) return context.tr('rating.tap_to_rate');
    if (_rating <= 1) return context.tr('rating.very_poor');
    if (_rating <= 2) return context.tr('rating.poor');
    if (_rating <= 3) return context.tr('rating.average');
    if (_rating <= 4) return context.tr('rating.good');
    return context.tr('rating.excellent');
  }

  Color _getRatingColor() {
    if (_rating == 0) return Colors.grey;
    if (_rating <= 1) return Colors.red;
    if (_rating <= 2) return Colors.orange;
    if (_rating <= 3) return Colors.amber;
    if (_rating <= 4) return Colors.lightGreen;
    return Colors.green;
  }

  void _submitRating() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('rating.please_select_rating')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final rating = DoctorRatingEntity.create(
      doctorId: widget.doctorId,
      patientId: widget.patientId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      rendezVousId: widget.appointmentId,
    );

    context.read<RatingBloc>().add(SubmitDoctorRating(rating));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RatingBloc, RatingState>(
      listener: (context, state) {
        if (state is RatingSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('rating.thank_you')),
              backgroundColor: Colors.green,
            ),
          );
          widget.onRatingSubmitted?.call();
          Navigator.of(context).pop(true);
        } else if (state is RatingError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),

                SizedBox(height: 24.h),

                // Doctor info
                _buildDoctorInfo(),

                SizedBox(height: 24.h),

                // Rating stars
                _buildRatingStars(),

                SizedBox(height: 12.h),

                // Rating text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _getRatingText(context),
                    key: ValueKey(_rating),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _getRatingColor(),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Comment field
                _buildCommentField(),

                SizedBox(height: 24.h),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.star_rounded,
            size: 40.sp,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          context.tr('rating.rate_your_experience'),
          style: GoogleFonts.raleway(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.tr('rating.your_feedback_helps'),
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.medical_services,
              color: AppColors.primaryColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: GoogleFonts.raleway(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  context.tr('rating.your_doctor'),
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars() {
    return RatingBar.builder(
      initialRating: _rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 48.sp,
      unratedColor: Colors.grey.shade300,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
      itemBuilder: (context, index) {
        return Icon(
          Icons.star_rounded,
          color: _getRatingColor(),
        );
      },
      onRatingUpdate: (rating) {
        setState(() => _rating = rating);
      },
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: context.tr('rating.add_comment_optional'),
        hintStyle: GoogleFonts.raleway(
          fontSize: 14.sp,
          color: Colors.grey.shade500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.all(16.w),
        counterStyle: GoogleFonts.raleway(
          fontSize: 12.sp,
          color: Colors.grey.shade500,
        ),
      ),
      style: GoogleFonts.raleway(fontSize: 14.sp),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    context.tr('rating.submit'),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget to display doctor ratings list
class DoctorRatingsWidget extends StatelessWidget {
  final List<DoctorRatingEntity> ratings;
  final double averageRating;

  const DoctorRatingsWidget({
    super.key,
    required this.ratings,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating header
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: GoogleFonts.raleway(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  RatingBarIndicator(
                    rating: averageRating,
                    itemBuilder: (context, _) => Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 16.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${ratings.length} ${'rating.reviews'.tr}',
                    style: GoogleFonts.raleway(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _buildRatingDistribution(),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Reviews list
        if (ratings.isEmpty)
          Padding(
            padding: EdgeInsets.all(24.w),
            child: EmptyStateWidget(
              message: context.tr('rating.no_reviews_yet'),
              animationSize: 120,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ratings.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildReviewItem(context, ratings[index]);
            },
          ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final rating in ratings) {
      final key = rating.rating.round();
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = distribution[star] ?? 0;
        final percentage = ratings.isEmpty ? 0.0 : count / ratings.length;

        return Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            children: [
              Text(
                '$star',
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.star, size: 12.sp, color: Colors.amber),
              SizedBox(width: 8.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$count',
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewItem(BuildContext context, DoctorRatingEntity rating) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  rating.patientName?.isNotEmpty == true
                      ? rating.patientName![0].toUpperCase()
                      : 'P',
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.patientName ?? context.tr('rating.anonymous'),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating.rating,
                          itemBuilder: (context, _) => Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 14.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatDate(context, rating.createdAt),
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(left: 48.w),
              child: Text(
                rating.comment!,
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return context.tr('rating.today');
    } else if (difference.inDays == 1) {
      return context.tr('rating.yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${context.tr('rating.days_ago')}';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} ${context.tr('rating.weeks_ago')}';
    } else {
      return '${(difference.inDays / 30).floor()} ${context.tr('rating.months_ago')}';
    }
  }
}
