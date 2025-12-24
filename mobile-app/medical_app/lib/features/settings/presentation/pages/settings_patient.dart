import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/injection_container.dart' as di;
import '../../../localisation/services/language_service.dart';
import 'change_password_screen.dart';

class SettingsPatient extends StatefulWidget {
  const SettingsPatient({super.key});

  @override
  State<SettingsPatient> createState() => _SettingsPatientState();
}

class _SettingsPatientState extends State<SettingsPatient> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settings.title'),
          style: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 24, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context.tr('settings.appearance')),
            const SizedBox(height: 8),
            const ThemeCubitSwitch(),

            const SizedBox(height: 24),
            _buildSectionTitle(context.tr('settings.language')),
            const SizedBox(height: 8),
            _buildLanguageSelection(),

            const SizedBox(height: 24),
            _buildSectionTitle(context.tr('settings.notifications')),
            const SizedBox(height: 8),
            _buildNotificationSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle(context.tr('settings.account')),
            const SizedBox(height: 8),
            _buildAccountSettings(),

            const SizedBox(height: 24),
            _buildSectionTitle(context.tr('settings.about')),
            const SizedBox(height: 8),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildLanguageOption('Français', 'fr'),
            const Divider(height: 1),
            _buildLanguageOption('English', 'en'),
            const Divider(height: 1),
            _buildLanguageOption('العربية', 'ar'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String langCode) {
    final isSelected = Get.locale?.languageCode == langCode;

    return InkWell(
      onTap: () async {
        await LanguageService.changeLocale(langCode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSwitchSetting(
              title: context.tr('settings.appointments'),
              icon: Icons.calendar_today,
              value: true,
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: context.tr('settings.medications'),
              icon: Icons.medication,
              value: true,
            ),
            const Divider(height: 1),
            _buildSwitchSetting(
              title: context.tr('settings.messages'),
              icon: Icons.message,
              value: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required IconData icon,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.raleway(fontSize: 14)),
            ],
          ),
          Switch(
            value: value,
            onChanged: (val) {
              // Implement notification settings logic
              setState(() {});
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primaryColor),
            title: Text(
              context.tr('settings.edit_profile'),
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () async {
              try {
                final authLocalDataSource = di.sl<AuthLocalDataSource>();
                final userModel = await authLocalDataSource.getUser();

                // Convert UserModel to PatientEntity
                PatientEntity patientEntity = PatientEntity(
                  id: userModel.id,
                  name: userModel.name,
                  lastName: userModel.lastName,
                  email: userModel.email,
                  role: userModel.role,
                  gender: userModel.gender,
                  phoneNumber: userModel.phoneNumber,
                  dateOfBirth: userModel.dateOfBirth,
                  antecedent:
                      userModel is PatientModel
                          ? (userModel as PatientModel).antecedent
                          : '',
                  // Add new MongoDB schema fields
                  bloodType:
                      userModel is PatientModel
                          ? (userModel as PatientModel).bloodType
                          : null,
                  height:
                      userModel is PatientModel
                          ? (userModel as PatientModel).height
                          : null,
                  weight:
                      userModel is PatientModel
                          ? (userModel as PatientModel).weight
                          : null,
                  allergies:
                      userModel is PatientModel
                          ? (userModel as PatientModel).allergies
                          : null,
                  chronicDiseases:
                      userModel is PatientModel
                          ? (userModel as PatientModel).chronicDiseases
                          : null,
                  emergencyContact:
                      userModel is PatientModel
                          ? (userModel as PatientModel).emergencyContact
                          : null,
                );

                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfileScreen(user: patientEntity),
                  ),
                );

                if (updatedUser != null && updatedUser is UserEntity) {
                  // Dispatch update event to the BLoC
                  context.read<UpdateUserBloc>().add(
                    UpdateUserEvent(updatedUser),
                  );

                  // Cache updated user if successful
                  if (userModel is PatientModel &&
                      updatedUser is PatientEntity) {
                    final PatientEntity patientUser =
                        updatedUser as PatientEntity;
                    await authLocalDataSource.cacheUser(
                      (userModel as PatientModel).copyWith(
                        name: patientUser.name,
                        lastName: patientUser.lastName,
                        phoneNumber: patientUser.phoneNumber,
                        gender: patientUser.gender,
                        dateOfBirth: patientUser.dateOfBirth,
                        antecedent: patientUser.antecedent,
                        // Update new MongoDB schema fields
                        bloodType: patientUser.bloodType,
                        height: patientUser.height,
                        weight: patientUser.weight,
                        allergies: patientUser.allergies,
                        chronicDiseases: patientUser.chronicDiseases,
                        emergencyContact: patientUser.emergencyContact,
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('settings.failed_to_load_profile'))),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primaryColor),
            title: Text(
              context.tr('settings.change_password'),
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              context.tr('settings.logout'),
              style: GoogleFonts.raleway(fontSize: 14, color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              // Logique de déconnexion
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.tr('settings.logout_success'))));
              // Rediriger vers la page de connexion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Medical App v1.0.0",
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('settings.copyright'),
              style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
