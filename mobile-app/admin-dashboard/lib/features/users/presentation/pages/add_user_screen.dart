// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1, // Users tab
      title: 'Add User',
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
                        'Add New User',
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
                                // Save new user using UserBloc
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              'Add User',
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
