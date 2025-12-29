import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/usecases/get_doctor_by_id_usecase.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDoctor();
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
              SizedBox(height: 100.h), // Space for bottom button
            ],
          ),
        ),
      ],
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
    );
  }
}
