import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../prescriptions/presentation/screens/my_prescriptions_screen.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../../domain/usecases/check_profile_completion_usecase.dart';
import '../blocs/patient_profile/profile_bloc.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showCompletionDialog;
  final bool showBackButton;
  
  const ProfileScreen({
    super.key,
    this.showCompletionDialog = true,
    this.showBackButton = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  bool _hasShownCompletionDialog = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(LoadProfile()),
      child: Scaffold(
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: _handleStateChanges,
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const ProfileShimmerLoading();
            }

            if (state is ProfileError) {
              return _buildErrorState(state);
            }

            if (state is ProfileLoaded ||
                state is ProfileUpdated ||
                state is PhotoUploading ||
                state is PhotoUploaded) {
              final profile = _getProfileFromState(state);
              if (profile != null) {
                return _buildProfileContent(context, profile, state);
              }
            }

            return const ProfileShimmerLoading();
          },
        ),
      ),
    );
  }

  PatientProfileEntity? _getProfileFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileUpdated) return state.profile;
    return null;
  }

  void _handleStateChanges(BuildContext context, ProfileState state) {
    if (state is ProfileLoaded) {
      // Check if we should show the completion dialog
      _checkAndShowCompletionDialog(state.profile);
    }
    
    if (state is PhotoUploaded) {
      setState(() => _selectedImage = null);
      AppSnackBar.success(
        context,
        'Profile photo updated successfully!',
      );
    }

    if (state is PhotoUploadError) {
      AppSnackBar.error(
        context,
        state.failure.message,
      );
    }

    if (state is ProfileError) {
      AppSnackBar.error(
        context,
        state.failure.message,
      );
    }
  }

  Future<void> _checkAndShowCompletionDialog(PatientProfileEntity profile) async {
    if (!widget.showCompletionDialog || _hasShownCompletionDialog) return;
    
    // Check if profile is incomplete
    if (!profile.isProfileComplete) {
      // Check if we should show the dialog (based on local storage tracking)
      final checkCompletionUseCase = sl<CheckProfileCompletionUseCase>();
      final markShownUseCase = sl<MarkProfileCompletionShownUseCase>();
      final shouldShow = await checkCompletionUseCase();
      
      if (shouldShow && mounted) {
        _hasShownCompletionDialog = true;
        
        // Show the completion dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          ProfileCompletionDialog.show(
            context,
            completionPercentage: profile.profileCompletionPercentage,
            onCompleteNow: () {
              // Navigate to edit profile screen (to be implemented)
              // For now, we'll just stay on the profile screen
              print('[ProfileScreen] User chose to complete profile now');
            },
            onLater: () async {
              print('[ProfileScreen] User chose to complete profile later');
              // Mark that we've shown the dialog for this session
              await markShownUseCase();
            },
          );
        }
      }
    }
  }

  void _navigateToEditProfile(BuildContext context, PatientProfileEntity profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    ).then((updated) {
      if (updated == true && mounted) {
        context.read<ProfileBloc>().add(LoadProfile());
      }
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3.w,
            color: AppColors.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProfileError state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              state.failure.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () {
                context.read<ProfileBloc>().add(LoadProfile());
              },
              width: 160.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    PatientProfileEntity profile,
    ProfileState state,
  ) {
    final isUploadingPhoto = state is PhotoUploading;
    final isNewProfile = profile.id.isEmpty;

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, profile),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(context, profile, isUploadingPhoto),
              SizedBox(height: 24.h),
              if (isNewProfile)
                _buildNewProfileBanner(context, profile)
              else
                _buildCompletionProgress(context, profile),
              SizedBox(height: 24.h),
              _buildPersonalInfoCard(context, profile),
              SizedBox(height: 16.h),
              _buildAddressCard(context, profile),
              SizedBox(height: 16.h),
              _buildMedicalInfoCard(context, profile),
              SizedBox(height: 16.h),
              _buildEmergencyContactCard(context, profile),
              SizedBox(height: 16.h),
              _buildInsuranceCard(context, profile),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewProfileBanner(BuildContext context, PatientProfileEntity profile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_rounded,
            size: 48.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Welcome! Let\'s Set Up Your Profile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Complete your profile to help doctors provide better care and make appointments easier.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Complete Profile',
            icon: Icons.edit_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(profile: profile),
                ),
              ).then((updated) {
                if (updated == true) {
                  context.read<ProfileBloc>().add(LoadProfile());
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, PatientProfileEntity profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.surface(context) : Colors.white,
      leading: widget.showBackButton
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
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Navigate to settings
          },
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 20.sp,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        SizedBox(width: 8.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    PatientProfileEntity profile,
    bool isUploadingPhoto,
  ) {
    final isNewProfile = profile.id.isEmpty;
    final displayName = isNewProfile ? 'New Patient' : profile.fullName;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          ProfileAvatar(
            imageUrl: profile.profilePhoto,
            localImage: _selectedImage,
            radius: 60,
            isEditable: !isNewProfile, // Disable photo upload for new profiles
            isLoading: isUploadingPhoto,
            onImagePicked: (filePath) {
              setState(() {
                _selectedImage = File(filePath);
              });
              context.read<ProfileBloc>().add(UploadPhoto(filePath: filePath));
            },
          ),
          SizedBox(height: 16.h),
          Text(
            displayName.isEmpty ? 'New Patient' : displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            profile.email ?? 'Complete your profile to add email',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
          if (profile.phone != null) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 16.sp,
                  color: AppColors.textHint(context),
                ),
                SizedBox(width: 4.w),
                Text(
                  profile.phone!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionProgress(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    final percentage = profile.profileCompletionPercentage;
    final Color progressColor;
    
    if (percentage >= 80) {
      progressColor = AppColors.success;
    } else if (percentage >= 50) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.primary;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withValues(alpha: 0.1),
            progressColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56.w,
                height: 56.h,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 6.w,
                  backgroundColor: progressColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isProfileComplete
                      ? 'Profile Complete!'
                      : 'Complete Your Profile',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile.isProfileComplete
                      ? 'Your profile is fully updated'
                      : 'Add more details to help doctors serve you better',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ],
            ),
          ),
          if (!profile.isProfileComplete)
            Icon(
              Icons.chevron_right_rounded,
              size: 24.sp,
              color: progressColor,
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return InfoCard(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      onEdit: () {
        _navigateToEditProfile(context, profile);
      },
      items: [
        InfoItem(
          label: 'Full Name',
          value: profile.fullName,
          icon: Icons.badge_outlined,
        ),
        InfoItem(
          label: 'Date of Birth',
          value: '${dateFormat.format(profile.dateOfBirth)} (${profile.age} years)',
          icon: Icons.cake_outlined,
        ),
        InfoItem(
          label: 'Gender',
          value: profile.gender.isNotEmpty
              ? profile.gender.substring(0, 1).toUpperCase() +
                  profile.gender.substring(1).toLowerCase()
              : null,
          icon: Icons.wc_outlined,
        ),
        InfoItem(
          label: 'Blood Type',
          value: profile.bloodType,
          icon: Icons.bloodtype_outlined,
        ),
      ],
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    return InfoCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      onEdit: () {
        _navigateToEditProfile(context, profile);
      },
      items: [
        InfoItem(
          label: 'Full Address',
          value: profile.address?.formattedAddress,
          icon: Icons.home_outlined,
        ),
      ],
    );
  }

  Widget _buildMedicalInfoCard(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    return InfoCard(
      title: 'Medical Information',
      icon: Icons.medical_services_outlined,
      onEdit: () {
        _navigateToEditProfile(context, profile);
      },
      children: [
        InfoRow(
          label: 'Allergies',
          value: profile.allergies?.isNotEmpty == true
              ? profile.allergies!.join(', ')
              : 'None',
          icon: Icons.warning_amber_rounded,
        ),
        Divider(color: AppColors.divider(context), height: 24.h),
        InfoRow(
          label: 'Chronic Diseases',
          value: profile.chronicDiseases?.isNotEmpty == true
              ? profile.chronicDiseases!.join(', ')
              : 'None',
              icon: Icons.healing_outlined,
        ),
        Divider(color: AppColors.divider(context), height: 24.h),
        InkWell(
          onTap: () => context.pushPage(
            const MyPrescriptionsScreen(),
            transition: NavTransition.slideLeft,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'View Prescriptions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactCard(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    return InfoCard(
      title: 'Emergency Contact',
      icon: Icons.emergency_outlined,
      onEdit: () {
        _navigateToEditProfile(context, profile);
      },
      items: [
        InfoItem(
          label: 'Contact Name',
          value: profile.emergencyContact?.name,
          icon: Icons.person_outline_rounded,
        ),
        InfoItem(
          label: 'Phone Number',
          value: profile.emergencyContact?.phone,
          icon: Icons.phone_outlined,
        ),
        InfoItem(
          label: 'Relationship',
          value: profile.emergencyContact?.relationship,
          icon: Icons.family_restroom_outlined,
        ),
      ],
    );
  }

  Widget _buildInsuranceCard(
    BuildContext context,
    PatientProfileEntity profile,
  ) {
    final insurance = profile.insuranceInfo;
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return InfoCard(
      title: 'Insurance Information',
      icon: Icons.health_and_safety_outlined,
      onEdit: () {
        _navigateToEditProfile(context, profile);
      },
      trailing: insurance != null && insurance.isExpired
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Expired',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            )
          : null,
      items: [
        InfoItem(
          label: 'Provider',
          value: insurance?.provider,
          icon: Icons.business_outlined,
        ),
        InfoItem(
          label: 'Policy Number',
          value: insurance?.policyNumber,
          icon: Icons.numbers_outlined,
        ),
        InfoItem(
          label: 'Valid Until',
          value: insurance?.expiryDate != null
              ? dateFormat.format(insurance!.expiryDate!)
              : null,
          icon: Icons.event_outlined,
        ),
      ],
    );
  }
}
