// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MainLayout(
      selectedIndex: 3, // Settings tab
      title: 'nav.settings'.tr(),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'settings.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Settings explanation
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings,
                        size: 64.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'settings.application_settings'.tr(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'settings.application_settings_description'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 24.h),

                      // Dark mode toggle example
                      ListTile(
                        title: Text(
                          'settings.dark_mode'.tr(),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        subtitle: Text(
                          'settings.dark_mode_description'.tr(),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            // Would be implemented with a SettingsBloc
                          },
                        ),
                      ),

                      // Account section
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is Authenticated) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(height: 32.h),
                                Text(
                                  'settings.account'.tr(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ListTile(
                                  title: Text(
                                    'auth.logout'.tr(),
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  subtitle: Text(
                                    'settings.sign_out_description'.tr(),
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  trailing: Icon(Icons.logout, size: 24.sp),
                                  onTap: () {
                                    _showLogoutConfirmation(context);
                                  },
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'auth.logout'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'auth.logout_confirm'.tr(),
              style: TextStyle(fontSize: 16.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('buttons.cancel'.tr(), style: TextStyle(fontSize: 14.sp)),
              ),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(Logout());
                  Navigator.of(context).pop();
                },
                child: Text(
                  'auth.logout'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
