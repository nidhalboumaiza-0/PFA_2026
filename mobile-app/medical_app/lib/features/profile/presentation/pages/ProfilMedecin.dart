import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/features/authentication/presentation/blocs/logout_bloc/logout_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:medical_app/features/profile/presentation/pages/change_password_screen.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

class ProfilMedecin extends StatefulWidget {
  const ProfilMedecin({Key? key}) : super(key: key);

  @override
  State<ProfilMedecin> createState() => _ProfilMedecinState();
}

class _ProfilMedecinState extends State<ProfilMedecin> {
  MedecinEntity? _medecin;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _medecin = MedecinEntity.create(
          id: userMap['id'] as String?,
          name: userMap['name'] as String,
          lastName: userMap['lastName'] as String,
          email: userMap['email'] as String,
          role: userMap['role'] as String,
          gender: userMap['gender'] as String,
          phoneNumber: userMap['phoneNumber'] as String,
          dateOfBirth:
              userMap['dateOfBirth'] != null
                  ? DateTime.parse(userMap['dateOfBirth'] as String)
                  : null,
          speciality: userMap['speciality'] as String?,
          numLicence: userMap['numLicence'] as String?,
          accountStatus: userMap['accountStatus'] as bool?,
          appointmentDuration: userMap['appointmentDuration'] as int,
          subSpecialty: userMap['subSpecialty'] as String?,
          clinicName: userMap['clinicName'] as String?,
          clinicAddress: userMap['clinicAddress'] as Map<String, dynamic>?,
          about: userMap['about'] as String?,
          languages: (userMap['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
          isVerified: userMap['isVerified'] as bool?,
          acceptsInsurance: userMap['acceptsInsurance'] as bool?,
          education: (userMap['education'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v.toString())))
              .toList(),
          experience: (userMap['experience'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v.toString())))
              .toList(),
          workingHours: (userMap['workingHours'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
          averageRating: (userMap['averageRating'] as num?)?.toDouble(),
          totalRatings: userMap['totalRatings'] as int?,
          consultationFee: (userMap['consultationFee'] as num?)?.toDouble(),
          acceptedInsurance: (userMap['acceptedInsurance'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
        );
      });
    }
  }

  // Translate specialty based on the value from the database
  String _translateSpecialty(String? specialty, BuildContext context) {
    if (specialty == null || specialty.isEmpty) {
      return context.tr('not_specified');
    }

    // Convert specialty to lowercase for case-insensitive matching
    final specialtyLower = specialty.toLowerCase();

    // Map of common specialties to their translation keys
    final Map<String, String> specialtyTranslationKeys = {
      'cardiology': 'cardiologist',
      'cardiologie': 'cardiologist',
      'dermatology': 'dermatologist',
      'dermatologie': 'dermatologist',
      'neurology': 'neurologist',
      'neurologie': 'neurologist',
      'pediatrics': 'pediatrician',
      'pédiatrie': 'pediatrician',
      'orthopedics': 'orthopedic',
      'orthopédie': 'orthopedic',
      'general': 'general_practitioner',
      'généraliste': 'general_practitioner',
      'psychology': 'psychologist',
      'psychologie': 'psychologist',
      'gynecology': 'gynecologist',
      'gynécologie': 'gynecologist',
      'ophthalmology': 'ophthalmologist',
      'ophtalmologie': 'ophthalmologist',
      'dentistry': 'dentist',
      'dentisterie': 'dentist',
      'pulmonology': 'pulmonologist',
      'pneumologie': 'pulmonologist',
      'nutrition': 'nutritionist',
      'esthétique': 'aesthetic_doctor',
      'aesthetic': 'aesthetic_doctor',
    };

    // Try to find a matching key in our map
    for (final entry in specialtyTranslationKeys.entries) {
      if (specialtyLower.contains(entry.key)) {
        return context.tr(entry.value);
      }
    }

    // If no match is found, return the original specialty
    return specialty;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('logout'), style: GoogleFonts.raleway(fontSize: 22.sp)),
        content: Text(
          context.tr('confirm_logout'),
          style: GoogleFonts.raleway(fontSize: 18.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.raleway(fontSize: 16.sp),
            ),
          ),
          BlocConsumer<LogoutBloc, LogoutState>(
            listener: (blocContext, state) {
              if (state is LogoutSuccess) {
                Navigator.of(dialogContext).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('logout_success'),
                      style: GoogleFonts.raleway(fontSize: 16.sp),
                    ),
                  ),
                );
                navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                  context,
                  const LoginScreen(),
                );
              } else if (state is LogoutError) {
                Navigator.of(dialogContext).pop(); // Close dialog
                showErrorSnackBar(context, state.message);
                // Force logout anyway on error
                navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                  context,
                  const LoginScreen(),
                );
              }
            },
            builder: (blocContext, state) {
              if (state is LogoutLoading) {
                return const CircularProgressIndicator();
              }
              return TextButton(
                onPressed: () {
                  blocContext.read<LogoutBloc>().add(LogoutRequested());
                },
                child: Text(
                  context.tr('logout'),
                  style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('change_profile_picture_message')),
      ),
    );
  }

  void _showAppointmentDurationDialog() {
    int selectedDuration = _medecin?.appointmentDuration ?? 30;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                context.tr('consultation_duration_label'),
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('choose_consultation_duration'),
                    style: GoogleFonts.raleway(fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${context.tr('duration_label')}: ',
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<int>(
                        value: selectedDuration,
                        items:
                            [15, 20, 30, 45, 60, 90, 120].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  '$value ${context.tr('minutes')}',
                                  style: GoogleFonts.raleway(fontSize: 16.sp),
                                ),
                              );
                            }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.tr('cancel'),
                    style: GoogleFonts.raleway(
                      color: Colors.grey,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      if (_medecin?.id != null) {
                        // Create updated doctor entity
                        final updatedDoctor = MedecinEntity(
                          id: _medecin!.id,
                          name: _medecin!.name,
                          lastName: _medecin!.lastName,
                          email: _medecin!.email,
                          role: _medecin!.role,
                          gender: _medecin!.gender,
                          phoneNumber: _medecin!.phoneNumber,
                          dateOfBirth: _medecin!.dateOfBirth,
                          speciality: _medecin!.speciality,
                          numLicence: _medecin!.numLicence,
                          appointmentDuration: selectedDuration,
                          subSpecialty: _medecin!.subSpecialty,
                          clinicName: _medecin!.clinicName,
                          clinicAddress: _medecin!.clinicAddress,
                          about: _medecin!.about,
                          languages: _medecin!.languages,
                          isVerified: _medecin!.isVerified,
                          acceptsInsurance: _medecin!.acceptsInsurance,
                          education: _medecin!.education,
                          experience: _medecin!.experience,
                          workingHours: _medecin!.workingHours,
                          averageRating: _medecin!.averageRating,
                          totalRatings: _medecin!.totalRatings,
                          consultationFee: _medecin!.consultationFee,
                          acceptedInsurance: _medecin!.acceptedInsurance,
                        );

                        // Dispatch update event
                        context.read<UpdateUserBloc>().add(UpdateUserEvent(updatedDoctor));
                      }
                    } catch (e) {
                      // Show error message
                      showErrorSnackBar(context, '${context.tr('update_error')}: $e');
                    }
                    // Close dialog
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.tr('confirm'),
                    style: GoogleFonts.raleway(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
          listener: (context, state) {
            if (state is UpdateUserSuccess) {
              setState(() {
                _medecin = state.user as MedecinEntity;
              });
              showSuccessSnackBar(context, context.tr('profile_saved_successfully'));
            } else if (state is UpdateUserFailure) {
              showErrorSnackBar(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is UpdateUserLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }
            return _medecin == null
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 24.h,
                    bottom: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Edit Profile Button (Top Right)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.edit, color: AppColors.primaryColor),
                          onPressed: () async {
                            final updatedUser = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        EditProfileScreen(user: _medecin!),
                              ),
                            );
                            if (updatedUser != null && mounted) {
                              setState(() {
                                _medecin = updatedUser as MedecinEntity;
                              });
                              _loadUserData(); // Reload to be sure
                            }
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50.r,
                                    backgroundColor: AppColors.primaryColor
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2fa7bb),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: AppColors.whiteColor,
                                        size: 18.sp,
                                      ),
                                      onPressed: _changeProfilePicture,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Dr. ${_medecin!.name} ${_medecin!.lastName}',
                              style: GoogleFonts.raleway(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _translateSpecialty(_medecin!.speciality, context),
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _medecin!.email,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        context.tr('personal_information'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ProfileInfoTile(
                        label: context.tr('phone_number_label'),
                        value: _medecin!.phoneNumber,
                      ),
                      ProfileInfoTile(label: context.tr('gender'), value: _medecin!.gender),
                      ProfileInfoTile(
                        label: context.tr('date_of_birth_label'),
                        value: _medecin!.dateOfBirth
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            context.tr('not_specified'),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        context.tr('professional_information'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ProfileInfoTile(
                        label: context.tr('specialty_label'),
                        value: _translateSpecialty(_medecin!.speciality, context),
                      ),
                      ProfileInfoTile(
                        label: context.tr('license_number_label'),
                        value: _medecin!.numLicence ?? context.tr('not_specified'),
                      ),
                      ProfileInfoTile(
                        label: context.tr('consultation_duration_label'),
                        value: '${_medecin!.appointmentDuration} ${context.tr('minutes')}',
                      ),
                      if (_medecin!.consultationFee != null)
                        ProfileInfoTile(
                          label: context.tr('consultation_fee'),
                          value: '${_medecin!.consultationFee} TND',
                        ),
                      if (_medecin!.clinicName != null)
                        ProfileInfoTile(label: context.tr('clinic_name'), value: _medecin!.clinicName!),
                      if (_medecin!.about != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(14.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('dashboard.about'),
                                    style: GoogleFonts.raleway(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _medecin!.about!,
                                    style: GoogleFonts.raleway(
                                      fontSize: 14.sp,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_medecin!.languages != null &&
                          _medecin!.languages!.isNotEmpty)
                        ProfileInfoTile(
                          label: context.tr('languages'),
                          value: _medecin!.languages!.join(', '),
                        ),
                      if (_medecin!.acceptedInsurance != null &&
                          _medecin!.acceptedInsurance!.isNotEmpty)
                        ProfileInfoTile(
                          label: context.tr('accepted_insurance'),
                          value: _medecin!.acceptedInsurance!.join(', '),
                        ),

                      SizedBox(height: 8.h),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _showAppointmentDurationDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('modify_consultation_duration'),
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Change Password Card
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('change_password'),
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
          },
        ),
      ),
    );
  }
}
