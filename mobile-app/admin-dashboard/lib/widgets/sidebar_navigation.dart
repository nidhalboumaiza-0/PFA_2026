import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/routes.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../widgets/responsive_layout.dart';
import '../config/theme.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;

  const SidebarNavigation({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    // Filter navigation items based on user role - we'll show all items for admin
    final filteredNavItems = navItems;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isAuthenticated = state is Authenticated;
        final UserEntity? user =
            isAuthenticated ? (state as Authenticated).user : null;

        return Container(
          width: isMobile ? 0 : 280.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: 32.h),
              // App logo / title
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 32.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Admin badge
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(50),
                  borderRadius: BorderRadius.circular(50.r),
                  border: Border.all(color: Colors.green.withAlpha(76)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Administrator Mode',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: const Divider(),
              ),
              SizedBox(height: 8.h),

              // Navigation label
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MENU',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(128),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Navigation items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  itemCount: filteredNavItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredNavItems[index];
                    final isSelected = index == selectedIndex;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color:
                            isSelected
                                ? AppTheme.primaryColor.withAlpha(25)
                                : Colors.transparent,
                      ),
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          size: 22.sp,
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(180),
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(204),
                          ),
                        ),
                        selected: isSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        onTap: () {
                          if (item.route != '') {
                            Navigator.pushReplacementNamed(context, item.route);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Bottom section
              Container(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Theme toggle
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: AppTheme.primaryColor,
                          size: 22.sp,
                        ),
                        title: Text(
                          isDarkMode ? 'Light Mode' : 'Dark Mode',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        onTap: () {
                          // You would implement theme switching using BLoC here
                        },
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // User info
                    if (user != null) ...[
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: AppTheme.primaryColor.withAlpha(
                                25,
                              ),
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            30.r,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              size: 12.sp,
                                              color: Colors.red.shade700,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              'Admin',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        icon: Icon(Icons.logout, size: 20.sp),
                        label: Text(
                          'LOGOUT',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: () => _showLogoutConfirmation(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Logout',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(fontSize: 16.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthBloc>().add(Logout());
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }
}
