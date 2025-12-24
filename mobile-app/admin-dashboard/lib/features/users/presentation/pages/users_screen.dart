// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../constants/routes.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    // Once you create a dedicated user management BLoC, you would fetch users here
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1,
      title: 'nav.users'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'users.management'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.person_add, size: 20.sp),
                  label: Text('users.add'.tr(), style: TextStyle(fontSize: 14.sp)),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.addUser);
                  },
                ),
              ],
            ),
          ),

          // User management explanation card
          Expanded(
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
                          Icons.people,
                          size: 64.sp,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'users.management'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'users.management_description'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.addUser);
                          },
                          child: Text(
                            'users.add'.tr(),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
