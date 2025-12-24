// Moved from screens directory to follow clean architecture
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/routes.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../config/theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics data
    _loadData();
  }

  void _loadData() {
    context.read<DashboardBloc>().add(LoadStats());
    context.read<DashboardBloc>().add(LoadAppointmentsPerDay());
    context.read<DashboardBloc>().add(LoadAppointmentsPerMonth());
    context.read<DashboardBloc>().add(LoadAppointmentsPerYear());
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2, // Statistics tab
      title: 'Statistics',
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Statistics Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.analytics, size: 20.sp),
                        label: Text(
                          'Advanced Statistics',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.advancedStatistics,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Statistics content
                Center(
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
                            Icons.bar_chart,
                            size: 64.sp,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Statistics Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'This screen would display various statistics and charts for monitoring platform performance. The BLoC pattern and clean architecture for dashboard statistics have been implemented. You can see this in action in the Advanced Statistics screen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            icon: Icon(Icons.analytics, size: 20.sp),
                            label: Text(
                              'Go to Advanced Statistics',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.advancedStatistics,
                              );
                            },
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
    );
  }
}
