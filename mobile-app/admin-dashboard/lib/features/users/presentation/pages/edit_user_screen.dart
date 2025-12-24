// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // This would typically receive a user ID from the route arguments
    // and use it to fetch the user details using a dedicated UserBloc

    return MainLayout(
      selectedIndex: 1, // Users tab
      title: 'Edit User',
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: SizedBox(
                width: 600.w,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit User',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'This screen needs to be connected to a UserBloc that would handle the CRUD operations for users. The BLoC pattern has been set up for auth and dashboard features.',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Save user using UserBloc
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 14.sp),
                            ),
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
      ),
    );
  }
}
