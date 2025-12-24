import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/util/snackbar_message.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'blocs/BLoC update profile/update_user_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/pages/dossier_medical_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:medical_app/features/authentication/presentation/blocs/logout_bloc/logout_bloc.dart';
import 'package:medical_app/features/settings/presentation/pages/SettingsPage.dart';

class ProfilePatient extends StatefulWidget {
  const ProfilePatient({Key? key}) : super(key: key);

  @override
  State<ProfilePatient> createState() => _ProfilePatientState();
}

class _ProfilePatientState extends State<ProfilePatient> {
  PatientEntity? _patient;

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

      // Process allergies if present
      List<String>? allergies;
      if (userMap['allergies'] is List) {
        allergies = List<String>.from(
          (userMap['allergies'] as List).map((item) => item.toString()),
        );
      } else {
        allergies = []; // Initialize with empty list to avoid null issues
      }

      // Process chronic diseases if present
      List<String>? chronicDiseases;
      if (userMap['chronicDiseases'] is List) {
        chronicDiseases = List<String>.from(
          (userMap['chronicDiseases'] as List).map((item) => item.toString()),
        );
      } else {
        chronicDiseases = []; // Initialize with empty list to avoid null issues
      }

      // Process emergency contact if present
      Map<String, String?>? emergencyContact;
      if (userMap['emergencyContact'] is Map) {
        emergencyContact = Map<String, String?>.from(
          (userMap['emergencyContact'] as Map).map(
            (key, value) => MapEntry(key.toString(), value?.toString()),
          ),
        );
      } else {
        emergencyContact = {}; // Initialize with empty map to avoid null issues
      }

      setState(() {
        _patient = PatientEntity(
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
          antecedent: userMap['antecedent'] as String? ?? '',
          bloodType: userMap['bloodType'] as String?,
          height:
              userMap['height'] != null
                  ? (userMap['height'] as num).toDouble()
                  : null,
          weight:
              userMap['weight'] != null
                  ? (userMap['weight'] as num).toDouble()
                  : null,
          allergies: allergies,
          chronicDiseases: chronicDiseases,
          emergencyContact: emergencyContact,
        );
      });
    }
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
                      context.tr("logout_success"),
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
        content: Text('${context.tr('info')}: ${context.tr('change_profile_picture_message')}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
          listener: (context, state) {
            if (state is UpdateUserSuccess) {
              setState(() {
                _patient = state.user as PatientEntity;
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
            return _patient == null
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppColors.primaryColor.withOpacity(0.15)
                                  : AppColors.primaryColor.withOpacity(0.1),
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
                                    color:
                                        isDarkMode
                                            ? Colors.grey[800]
                                            : AppColors.whiteColor,
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
                                  child: GestureDetector(
                                    onTap: _changeProfilePicture,
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '${_patient!.name} ${_patient!.lastName}',
                              style: GoogleFonts.raleway(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _patient!.email,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          context.tr('personal_information'),
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ProfileInfoTile(
                        label: context.tr('phone_number_label'),
                        value: _patient!.phoneNumber,
                      ),
                      ProfileInfoTile(label: context.tr('gender'), value: _patient!.gender),
                      ProfileInfoTile(
                        label: context.tr('date_of_birth_label'),
                        value: _patient!.dateOfBirth
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            context.tr('not_specified'),
                      ),
                      ProfileInfoTile(
                        label: context.tr('antecedent'),
                        value: _patient!.antecedent ?? context.tr('not_specified'),
                      ),
                      if (_patient!.bloodType != null)
                        ProfileInfoTile(label: context.tr('blood_type'), value: _patient!.bloodType!),
                      if (_patient!.height != null)
                        ProfileInfoTile(label: context.tr('height'), value: '${_patient!.height} cm'),
                      if (_patient!.weight != null)
                        ProfileInfoTile(label: context.tr('weight'), value: '${_patient!.weight} kg'),
                      SizedBox(height: 20.h),
                      _buildMedicalInformationSection(),
                      SizedBox(height: 20.h),
                      if (_patient!.emergencyContact != null &&
                          _patient!.emergencyContact!.isNotEmpty) ...[
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            context.tr('emergency_contact'),
                            style: GoogleFonts.raleway(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              children: [
                                if (_patient!.emergencyContact!['name'] != null)
                                  _buildEmergencyContactRow(
                                    Icons.person,
                                    context.tr('emergency_contact_name'),
                                    _patient!.emergencyContact!['name']!,
                                  ),
                                if (_patient!
                                        .emergencyContact!['relationship'] !=
                                    null)
                                  _buildEmergencyContactRow(
                                    Icons.people,
                                    context.tr('emergency_relationship'),
                                    _patient!
                                        .emergencyContact!['relationship']!,
                                  ),
                                if (_patient!
                                        .emergencyContact!['phoneNumber'] !=
                                    null)
                                  _buildEmergencyContactRow(
                                    Icons.phone,
                                    context.tr('emergency_phone'),
                                    _patient!.emergencyContact!['phoneNumber']!,
                                    isLast: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          context.tr('settings'),
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: () {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                            context,
                            const SettingsPage(),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.settings,
                              color: AppColors.primaryColor,
                            ),
                            title: Text(
                              context.tr('app_settings'),
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primaryColor,
                              size: 16.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          context.tr('medical_records'),
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: () {
                          if (_patient?.id != null) {
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                              context,
                              BlocProvider<DossierMedicalBloc>(
                                create:
                                    (context) => di.sl<DossierMedicalBloc>(),
                                child: DossierMedicalScreen(
                                  patientId: _patient!.id!,
                                ),
                              ),
                            );
                          } else {
                            SnackBarMessage().showErrorSnackBar(
                              message: context.tr('medical_record_access_error'),
                              context: context,
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.folder_shared_outlined,
                              color: AppColors.primaryColor,
                              size: 20.sp,
                            ),
                            title: Text(
                              context.tr('manage_medical_records'),
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primaryColor,
                              size: 16.sp,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: Icon(Icons.logout, size: 18.sp),
                            label: Text(
                              context.tr('logout'),
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                );
          },
        ),
      ),
    );
  }

  Widget _buildMedicalInformationSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool hasAllergies =
        _patient!.allergies != null && _patient!.allergies!.isNotEmpty;
    final bool hasChronicDiseases =
        _patient!.chronicDiseases != null &&
        _patient!.chronicDiseases!.isNotEmpty;

    // Only show this section if there are allergies or chronic diseases
    if (!hasAllergies && !hasChronicDiseases) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            context.tr('medical_information'),
            style: GoogleFonts.raleway(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Allergies
        if (hasAllergies)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              title: Text(
                context.tr('allergies'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
              childrenPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _patient!.allergies!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8.sp,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _patient!.allergies![index],
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        // Chronic Diseases
        if (hasChronicDiseases)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              title: Text(
                context.tr('chronic_diseases'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              leading: Icon(
                Icons.medical_services_outlined,
                color: Colors.red[400],
              ),
              childrenPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _patient!.chronicDiseases!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8.sp,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _patient!.chronicDiseases![index],
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyContactRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.raleway(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
