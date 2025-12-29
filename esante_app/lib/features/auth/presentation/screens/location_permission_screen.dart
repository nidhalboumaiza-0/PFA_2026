import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/navigation_utils.dart'; // Import navigation utils
import '../../../../core/widgets/app_text.dart'; // Import AppText
import '../../../../core/widgets/app_dialog.dart'; // Import AppDialog
import '../../../../injection_container.dart';
import '../../../dashboard/presentation/screens/patient_main_navigation.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/user_entity.dart';

class LocationPermissionScreen extends StatefulWidget {
  final UserEntity user;
  final bool showProfileCompletionDialog;
  final int profileCompletionPercentage;

  const LocationPermissionScreen({
    super.key,
    required this.user,
    this.showProfileCompletionDialog = false,
    this.profileCompletionPercentage = 0,
  });

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _handleAllowLocation() async {
    setState(() => _isLoading = true);

    try {
      // 1. Check/Request Permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
           _showError('Location services are disabled. Please enable them in settings.');
           setState(() => _isLoading = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            _handleSkip(); 
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _handleSkip();
        }
        return;
      }

      // 2. Get Location
      Position position = await Geolocator.getCurrentPosition();

      // 3. Update Profile
      final profileRepository = sl<ProfileRepository>();
      final profileResult = await profileRepository.getPatientProfile();
      
      await profileResult.fold(
        (failure) async {
           _showError('Failed to fetch profile data.');
        },
        (profile) async {
             // Construct address map
            final addressMap = <String, dynamic>{
              if (profile.address?.street != null) 'street': profile.address!.street,
              if (profile.address?.city != null) 'city': profile.address!.city,
              if (profile.address?.state != null) 'state': profile.address!.state,
              if (profile.address?.zipCode != null) 'zipCode': profile.address!.zipCode,
              if (profile.address?.country != null) 'country': profile.address!.country,
              'coordinates': {
                'type': 'Point',
                'coordinates': [position.longitude, position.latitude],
              }
            };

            await profileRepository.updatePatientProfile(address: addressMap);
        },
      );

      if (mounted) {
        _navigateToDashboard();
      }

    } catch (e) {
      if (mounted) {
        _showError('An error occurred: $e');
        _navigateToDashboard(); // Fallback
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip() {
    // Show popup explaining necessity using AppDialog
    AppDialog.warning(
      context,
      title: 'Location Required',
      message: 'You need to activate localization later when you want to make an appointment.',
      buttonText: 'Understood',
      onPressed: _navigateToDashboard,
    );
  }

  void _navigateToDashboard() {
    context.pushAndClearStack(
      PatientMainNavigation(
        showProfileCompletionDialog: widget.showProfileCompletionDialog,
        profileCompletionPercentage: widget.profileCompletionPercentage,
      ),
      transition: NavTransition.fadeScale,
    );
  }
  
  void _showError(String message) {
    AppSnackBar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor, // Use extension if available, or AppColors
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Spacer(),
              // Icon
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 100.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 40.h),
              
              AppTitle(
                text: 'Enable Location',
                emoji: '📍',
              ),
              SizedBox(height: 16.h),
              AppSubtitle(
                text: 'We need your location to find doctors and clinics near you. This helps us provide the best healthcare experience.',
                maxLines: 3,
              ),
              
              Spacer(),
              
              CustomButton(
                text: 'Allow Location Access',
                onPressed: _handleAllowLocation,
                isLoading: _isLoading,
                icon: Icons.near_me_rounded,
              ),
              SizedBox(height: 16.h),
              CustomButton(
                text: 'Skip for now',
                onPressed: _isLoading ? null : _handleSkip,
                isOutlined: true,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
