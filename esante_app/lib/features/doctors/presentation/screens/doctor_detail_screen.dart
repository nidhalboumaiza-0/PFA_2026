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
        // Modern App Bar with gradient
        SliverAppBar(
          expandedHeight: 320.h,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: Padding(
            padding: EdgeInsets.all(8.r),
            child: AppBackButton(
              iconColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildModernHeader(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Cards
              Padding(
                padding: EdgeInsets.all(16.w),
                child: _buildQuickStatsCards(),
              ),

              // About Section
              if (_doctor!.yearsOfExperience != null || 
                  (_doctor!.languages != null && _doctor!.languages!.isNotEmpty))
                _buildAboutSection(),

              // Consultation Fee Highlight
              if (_doctor!.consultationFee != null)
                _buildConsultationFeeCard(),

              // Clinic Info Section
              _buildClinicSection(),

              // Reviews Section
              _buildReviewsSection(),
              
              SizedBox(height: 100.h), // Space for bottom button
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            const Color(0xFF1E88E5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Profile Photo
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55.r,
                backgroundColor: Colors.white,
                backgroundImage: _doctor!.profilePhoto != null
                    ? NetworkImage(_doctor!.profilePhoto!)
                    : null,
                child: _doctor!.profilePhoto == null
                    ? Icon(Icons.person, size: 50.sp, color: AppColors.primary)
                    : null,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Doctor Name
            Text(
              'Dr. ${_doctor!.fullName}',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            
            // Specialty Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medical_services, size: 16.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    _doctor!.displaySpecialty,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (_doctor!.isVerified) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.verified, color: Colors.white, size: 18.sp),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    return Row(
      children: [
        // Rating Card
        if (_doctor!.rating != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              value: _doctor!.rating!.toStringAsFixed(1),
              label: 'Rating',
              bgColor: Colors.amber.withOpacity(0.1),
            ),
          ),
        SizedBox(width: 12.w),
        
        // Reviews Card
        if (_doctor!.reviewCount != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_rounded,
              iconColor: AppColors.primary,
              value: _doctor!.reviewCount.toString(),
              label: 'Reviews',
              bgColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
        SizedBox(width: 12.w),
        
        // Experience Card
        if (_doctor!.yearsOfExperience != null)
          Expanded(
            child: _buildStatCard(
              icon: Icons.workspace_premium_rounded,
              iconColor: Colors.green,
              value: '${_doctor!.yearsOfExperience}+',
              label: 'Years Exp.',
              bgColor: Colors.green.withOpacity(0.1),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('About Doctor', Icons.info_outline),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_doctor!.yearsOfExperience != null)
                  _buildInfoRowModern(
                    Icons.work_history_rounded,
                    'Experience',
                    '${_doctor!.yearsOfExperience} years of experience',
                    Colors.blue,
                  ),
                if (_doctor!.languages != null && _doctor!.languages!.isNotEmpty) ...[
                  if (_doctor!.yearsOfExperience != null)
                    Divider(height: 24.h, color: Colors.grey[200]),
                  _buildInfoRowModern(
                    Icons.translate_rounded,
                    'Languages',
                    _doctor!.languages!.join(', '),
                    Colors.purple,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildConsultationFeeCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consultation Fee',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${_doctor!.consultationFee} TND',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Per Visit',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicSection() {
    if (_doctor!.clinicName == null && _doctor!.clinicAddress == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Clinic Information', Icons.local_hospital_outlined),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_doctor!.clinicName != null)
                  _buildInfoRowModern(
                    Icons.business_rounded,
                    'Clinic Name',
                    _doctor!.clinicName!,
                    Colors.teal,
                  ),
                if (_doctor!.clinicName != null && _doctor!.clinicAddress != null)
                  Divider(height: 24.h, color: Colors.grey[200]),
                if (_doctor!.clinicAddress != null)
                  _buildInfoRowModern(
                    Icons.location_on_rounded,
                    'Address',
                    _doctor!.clinicAddress!.fullAddress,
                    Colors.red,
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowModern(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Patient Reviews', Icons.star_rounded),
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
          SizedBox(height: 12.h),

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
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Text(
                  _ratingStats!.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final filled = index < _ratingStats!.averageRating.floor();
                    final partial = index == _ratingStats!.averageRating.floor() &&
                        _ratingStats!.averageRating % 1 > 0;
                    return Icon(
                      partial ? Icons.star_half_rounded : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
                      color: Colors.amber,
                      size: 14.sp,
                    );
                  }),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_ratingStats!.totalReviews} reviews',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          // Rating Breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final percentage = _ratingStats!.getPercentage(stars);
                return Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    children: [
                      Text(
                        '$stars',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 12.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 8.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 35.w,
                        child: Text(
                          '${(percentage * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
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
