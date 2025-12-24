// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This would typically receive a user ID from the route arguments
    // and use it to fetch the user details using a dedicated UserBloc

    return MainLayout(
      selectedIndex: 1, // Users tab
      title: 'User Details',
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: SizedBox(
            width: 600.w,
            child: Card(
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
                      Icons.person,
                      size: 64.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'User Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'This screen would display detailed information about a specific user. To implement this properly, you would need to create a dedicated UserBloc following the same clean architecture and BLoC pattern used for auth and dashboard features.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.arrow_back, size: 20.sp),
                          label: Text(
                            'Back to Users',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton.icon(
                          icon: Icon(Icons.edit, size: 20.sp),
                          label: Text(
                            'Edit User',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.editUser);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
