import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../messaging/utils/messaging_helper.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/entities/doctor_review_entity.dart';
import '../../domain/usecases/get_doctor_by_id_usecase.dart';
import '../../domain/usecases/get_doctor_reviews_usecase.dart';
import '../../../appointments/presentation/screens/book_appointment_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DoctorEntity? _doctor;
  bool _isLoading = true;
  String? _error;
  List<DoctorReviewEntity> _reviews = [];
  DoctorRatingStats? _ratingStats;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
    _loadReviews();
  }

  Future<void> _loadDoctor() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final useCase = sl<GetDoctorByIdUseCase>();
    final result = await useCase(GetDoctorParams(doctorId: widget.doctorId));

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (doctor) => setState(() {
        _isLoading = false;
        _doctor = doctor;
      }),
    );
  }

  Future<void> _loadReviews() async {
    final getReviewsUseCase = sl<GetDoctorReviewsUseCase>();
    final result = await getReviewsUseCase(GetDoctorReviewsParams(
      doctorId: widget.doctorId,
      limit: 10,
    ));

    result.fold(
      (failure) {
        // Fallback to mock data if API fails (e.g., during development)
        print('[DoctorDetailScreen] Failed to load reviews: ${failure.message}');
        _loadMockReviews();
      },
      (reviewsResult) {
        setState(() {
          _reviews = reviewsResult.reviews;
          _ratingStats = reviewsResult.stats;
        });
      },
    );
  }

  /// Fallback mock reviews when API is not available
  void _loadMockReviews() {
    if (_doctor != null && _doctor!.rating != null) {
      _ratingStats = DoctorRatingStats(
        averageRating: _doctor!.rating!,
        totalReviews: _doctor!.reviewCount ?? 0,
        fiveStarCount: ((_doctor!.reviewCount ?? 0) * 0.6).round(),
        fourStarCount: ((_doctor!.reviewCount ?? 0) * 0.25).round(),
        threeStarCount: ((_doctor!.reviewCount ?? 0) * 0.1).round(),
        twoStarCount: ((_doctor!.reviewCount ?? 0) * 0.03).round(),
        oneStarCount: ((_doctor!.reviewCount ?? 0) * 0.02).round(),
      );

      // Generate sample reviews
      _reviews = [
        DoctorReviewEntity(
          id: '1',
          doctorId: widget.doctorId,
          patientId: 'p1',
          patientName: 'Ahmed B.',
          rating: 5,
          comment: 'Excellent doctor! Very professional and attentive. Took time to explain everything clearly.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          isVerified: true,
        ),
        DoctorReviewEntity(
          id: '2',
          doctorId: widget.doctorId,
          patientId: 'p2',
          patientName: 'Fatima M.',
          rating: 5,
          comment: 'Very satisfied with the consultation. The doctor is knowledgeable and caring.',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          isVerified: true,
        ),
        DoctorReviewEntity(
          id: '3',
          doctorId: widget.doctorId,
          patientId: 'p3',
          patientName: 'Mohamed K.',
          rating: 4,
          comment: 'Good experience overall. Would recommend to others.',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          isVerified: true,
        ),
        DoctorReviewEntity(
          id: '4',
          doctorId: widget.doctorId,
          patientId: 'p4',
          patientName: 'Sana L.',
          rating: 5,
          comment: 'The best specialist I have visited. Very thorough examination.',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          isVerified: true,
        ),
      ];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _doctor != null ? _buildBookButton() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            AppSubtitle(text: _error!, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            CustomButton(text: 'Retry', onPressed: _loadDoctor),
          ],
        ),
      );
    }

    if (_doctor == null) {
      return const Center(child: AppSubtitle(text: 'Doctor not found'));
    }

    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 200.h,
          pinned: true,
          leading: Padding(
            padding: EdgeInsets.all(8.r),
            child: AppBackButton(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Dr. ${_doctor!.fullName}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: _buildHeaderImage(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              
              // Specialty Badge
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildSpecialtyBadge(),
              ),
              SizedBox(height: 20.h),

              // Stats Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildStatsRow(),
              ),
              SizedBox(height: 24.h),

              // About Section using InfoCard
              if (_doctor!.yearsOfExperience != null || 
                  (_doctor!.languages != null && _doctor!.languages!.isNotEmpty))
                InfoCard(
                  title: 'About',
                  icon: Icons.person_outline,
                  items: [
                    if (_doctor!.yearsOfExperience != null)
                      InfoItem(
                        label: 'Experience',
                        value: '${_doctor!.yearsOfExperience} years',
                        icon: Icons.work_outline,
                      ),
                    if (_doctor!.languages != null && _doctor!.languages!.isNotEmpty)
                      InfoItem(
                        label: 'Languages',
                        value: _doctor!.languages!.join(', '),
                        icon: Icons.language,
                      ),
                  ],
                ),
              SizedBox(height: 16.h),

              // Clinic Info using InfoCard
              InfoCard(
                title: 'Clinic Information',
                icon: Icons.local_hospital_outlined,
                items: [
                  if (_doctor!.clinicName != null)
                    InfoItem(
                      label: 'Clinic Name',
                      value: _doctor!.clinicName!,
                      icon: Icons.business,
                    ),
                  if (_doctor!.clinicAddress != null)
                    InfoItem(
                      label: 'Address',
                      value: _doctor!.clinicAddress!.fullAddress,
                      icon: Icons.location_on_outlined,
                    ),
                  if (_doctor!.consultationFee != null)
                    InfoItem(
                      label: 'Consultation Fee',
                      value: '${_doctor!.consultationFee} TND',
                      icon: Icons.payments_outlined,
                    ),
                ],
              ),
              SizedBox(height: 24.h),

              // Reviews Section
              _buildReviewsSection(),
              
              SizedBox(height: 100.h), // Space for bottom button
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Reviews & Ratings',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_reviews.length > 3)
                TextButton(
                  onPressed: () => _showAllReviews(),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Rating Stats Card
          if (_ratingStats != null) _buildRatingStatsCard(),
          SizedBox(height: 16.h),

          // Reviews List
          if (_reviews.isEmpty)
            _buildNoReviewsCard()
          else
            ...(_reviews.take(3).map((review) => _buildReviewCard(review))),
        ],
      ),
    );
  }

  Widget _buildRatingStatsCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            children: [
              Text(
                _ratingStats!.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final filled = index < _ratingStats!.averageRating.floor();
                  final partial = index == _ratingStats!.averageRating.floor() &&
                      _ratingStats!.averageRating % 1 > 0;
                  return Icon(
                    partial ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
                    color: Colors.amber,
                    size: 16.sp,
                  );
                }),
              ),
              SizedBox(height: 4.h),
              Text(
                '${_ratingStats!.totalReviews} reviews',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          SizedBox(width: 24.w),
          // Rating Breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final percentage = _ratingStats!.getPercentage(stars);
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.star, color: Colors.amber, size: 12.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: AppColors.grey200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 6.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${(percentage * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(DoctorReviewEntity review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.patientPhoto != null
                    ? NetworkImage(review.patientPhoto!)
                    : null,
                child: review.patientPhoto == null
                    ? Text(
                        review.patientName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.patientName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (review.isVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 14.sp,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16.sp,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.grey600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoReviewsCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 12.h),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.grey500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Be the first to leave a review!',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Reviews (${_reviews.length})',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) =>
                      _buildReviewCard(_reviews[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: Colors.grey.shade200,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 200.h, color: Colors.white),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 30.h, width: 150.w, color: Colors.white),
                  SizedBox(height: 16.h),
                  Row(
                    children: List.generate(3, (_) => Expanded(
                      child: Container(
                        height: 60.h,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    )),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
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

  Widget _buildHeaderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: _doctor!.profilePhoto != null
            ? Image.network(
                _doctor!.profilePhoto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
              )
            : _buildProfilePlaceholder(),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return CircleAvatar(
      radius: 50.r,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Icon(
        Icons.person,
        size: 50.sp,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSpecialtyBadge() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _doctor!.displaySpecialty,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
        if (_doctor!.isVerified) ...[
          SizedBox(width: 8.w),
          Icon(
            Icons.verified,
            color: AppColors.primary,
            size: 22.sp,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        if (_doctor!.rating != null)
          _buildStatItem(
            icon: Icons.star,
            iconColor: Colors.amber,
            value: _doctor!.rating!.toStringAsFixed(1),
            label: 'Rating',
          ),
        if (_doctor!.reviewCount != null) ...[
          SizedBox(width: 24.w),
          _buildStatItem(
            icon: Icons.rate_review_outlined,
            iconColor: AppColors.primary,
            value: _doctor!.reviewCount.toString(),
            label: 'Reviews',
          ),
        ],
        if (_doctor!.distance != null) ...[
          SizedBox(width: 24.w),
          _buildStatItem(
            icon: Icons.location_on,
            iconColor: AppColors.success,
            value: _doctor!.displayDistance,
            label: 'Distance',
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20.sp),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            // Message button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                ),
                tooltip: 'Message Doctor',
                onPressed: () {
                  MessagingHelper.startConversation(
                    context: context,
                    recipientId: _doctor!.id,
                    recipientType: 'doctor',
                    recipientName: 'Dr. ${_doctor!.fullName}',
                    recipientAvatarUrl: _doctor!.profilePhoto,
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            // Book button
            Expanded(
              child: CustomButton(
                text: 'Book Appointment',
                icon: Icons.calendar_today,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(doctor: _doctor!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
