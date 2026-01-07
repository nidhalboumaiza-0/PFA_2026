import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/doctor_profile_entity.dart';
import '../blocs/doctor_profile/doctor_profile_bloc.dart';
import 'edit_doctor_profile_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final bool showBackButton;
  
  const DoctorProfileScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DoctorProfileBloc>()..add(LoadDoctorProfile()),
      child: _DoctorProfileView(showBackButton: showBackButton),
    );
  }
}

class _DoctorProfileView extends StatelessWidget {
  final bool showBackButton;
  
  const _DoctorProfileView({
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: BlocConsumer<DoctorProfileBloc, DoctorProfileState>(
        listener: (context, state) {
          if (state is DoctorProfileError) {
            AppSnackBar.error(context, state.failure.message);
          } else if (state is DoctorProfileUpdated) {
            AppSnackBar.success(context, 'Profile updated successfully!');
          } else if (state is DoctorPhotoUploaded) {
            AppSnackBar.success(context, 'Photo uploaded successfully!');
          }
        },
        builder: (context, state) {
          if (state is DoctorProfileLoading) {
            return const DoctorProfileShimmerLoading();
          }

          if (state is DoctorProfileLoaded || state is DoctorProfileUpdated) {
            final profile = state is DoctorProfileLoaded
                ? state.profile
                : (state as DoctorProfileUpdated).profile;
            return _buildProfileContent(context, profile, state);
          }

          if (state is DoctorProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: AppColors.error),
                  SizedBox(height: 16.h),
                  Text(
                    state.failure.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<DoctorProfileBloc>().add(LoadDoctorProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    DoctorProfileEntity profile,
    DoctorProfileState state,
  ) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, profile),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(context, profile, state is DoctorPhotoUploading),
              SizedBox(height: 24.h),
              _buildCompletionProgress(context, profile),
              SizedBox(height: 24.h),
              _buildProfessionalInfoCard(context, profile),
              SizedBox(height: 16.h),
              _buildClinicInfoCard(context, profile),
              SizedBox(height: 16.h),
              _buildEducationCard(context, profile),
              SizedBox(height: 16.h),
              _buildAboutCard(context, profile),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, DoctorProfileEntity profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.surface(context) : Colors.white,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.sp,
                  color: AppColors.textPrimary(context),
                ),
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToEditProfile(context, profile),
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: AppColors.primary,
              size: 20.sp,
            ),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  void _navigateToEditProfile(BuildContext context, DoctorProfileEntity profile) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditDoctorProfileScreen(profile: profile),
      ),
    );

    if (updated == true && context.mounted) {
      context.read<DoctorProfileBloc>().add(LoadDoctorProfile());
    }
  }

  Widget _buildProfileHeader(
    BuildContext context,
    DoctorProfileEntity profile,
    bool isUploadingPhoto,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Profile photo
          ProfileAvatar(
            imageUrl: profile.profilePhoto,
            isEditable: true,
            isLoading: isUploadingPhoto,
            onImagePicked: (filePath) {
              context.read<DoctorProfileBloc>().add(
                    UploadDoctorPhoto(filePath: filePath),
                  );
            },
          ),
          SizedBox(height: 16.h),
          // Name
          Text(
            profile.fullName.isNotEmpty ? 'Dr. ${profile.fullName}' : 'Complete Your Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 4.h),
          // Specialty
          Text(
            profile.specialty.isNotEmpty ? profile.specialty : 'Add your specialty',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 8.h),
          // Rating
          if (profile.totalReviews > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 20.sp),
                SizedBox(width: 4.w),
                Text(
                  '${profile.rating.toStringAsFixed(1)} (${profile.totalReviews} reviews)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }



  Widget _buildCompletionProgress(BuildContext context, DoctorProfileEntity profile) {
    final completion = profile.profileCompletionPercentage;
    final isComplete = completion >= 80;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: isComplete ? AppColors.success : AppColors.warning,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'Profile Complete!' : 'Complete Your Profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 4.h),
                LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '$completion%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isComplete ? AppColors.success : AppColors.warning,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard(BuildContext context, DoctorProfileEntity profile) {
    return InfoCard(
      title: 'Professional Information',
      icon: Icons.medical_services_outlined,
      onEdit: () => _navigateToEditProfile(context, profile),
      children: [
        InfoRow(label: 'License Number', value: profile.licenseNumber),
        InfoRow(label: 'Specialty', value: profile.specialty),
        if (profile.subSpecialty != null && profile.subSpecialty!.isNotEmpty)
          InfoRow(label: 'Sub-Specialty', value: profile.subSpecialty!),
        InfoRow(label: 'Experience', value: '${profile.yearsOfExperience} years'),
        InfoRow(label: 'Phone', value: profile.phone),
        InfoRow(
          label: 'Consultation Fee',
          value: profile.consultationFee > 0 ? '\$${profile.consultationFee.toStringAsFixed(0)}' : 'Not set',
        ),
        InfoRow(
          label: 'Accepts Insurance',
          value: profile.acceptsInsurance ? 'Yes' : 'No',
        ),
      ],
    );
  }

  Widget _buildClinicInfoCard(BuildContext context, DoctorProfileEntity profile) {
    return InfoCard(
      title: 'Clinic Information',
      icon: Icons.location_on_outlined,
      onEdit: () => _navigateToEditProfile(context, profile),
      children: [
        if (profile.clinicName != null && profile.clinicName!.isNotEmpty)
          InfoRow(label: 'Clinic Name', value: profile.clinicName!),
        if (profile.clinicAddress != null)
          InfoRow(label: 'Address', value: profile.clinicAddress!.formattedAddress),
      ],
    );
  }

  Widget _buildAboutCard(BuildContext context, DoctorProfileEntity profile) {
    return InfoCard(
      title: 'About',
      icon: Icons.person_outline,
      onEdit: () => _navigateToEditProfile(context, profile),
      children: [
        if (profile.about != null && profile.about!.isNotEmpty)
          Text(
            profile.about!,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Text(
            'Add a description about yourself...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
          ),
        if (profile.languages.isNotEmpty) ...[
          SizedBox(height: 12.h),
          InfoRow(label: 'Languages', value: profile.languages.join(', ')),
        ],
      ],
    );
  }

  Widget _buildEducationCard(BuildContext context, DoctorProfileEntity profile) {
    return InfoCard(
      title: 'Education',
      icon: Icons.school_outlined,
      onEdit: () => _navigateToEditProfile(context, profile),
      children: profile.education.isEmpty
          ? [
              Text(
                'Add your education details...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ]
          : profile.education
              .map((edu) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                edu.degree,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                edu.institution,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary(context),
                                    ),
                              ),
                              if (edu.year != null) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  edu.year.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary(context),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
    );
  }
}
