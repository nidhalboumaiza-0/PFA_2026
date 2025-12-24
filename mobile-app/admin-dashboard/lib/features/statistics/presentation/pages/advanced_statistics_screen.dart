import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../features/dashboard/domain/entities/stats_entity.dart';
import '../../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../../widgets/dashboard/user_stats_table.dart';
import '../../../../widgets/main_layout.dart';
import '../../../../widgets/responsive_layout.dart';

class AdvancedStatisticsScreen extends StatefulWidget {
  const AdvancedStatisticsScreen({super.key});

  @override
  State<AdvancedStatisticsScreen> createState() =>
      _AdvancedStatisticsScreenState();
}

class _AdvancedStatisticsScreenState extends State<AdvancedStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load the stats data
    _loadData();
  }

  void _loadData() {
    final bloc = context.read<DashboardBloc>();
    bloc.add(LoadTopDoctorsByCompletedAppointments());
    bloc.add(LoadTopDoctorsByCancelledAppointments());
    bloc.add(LoadTopPatientsByCancelledAppointments());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2, // Adjust based on your navigation bar
      title: 'Advanced Statistics',
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'User Statistics Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(fontSize: 14.sp),
                  indicatorWeight: 3.h,
                  tabs: [
                    Tab(
                      text: 'Top Doctors (Completed)',
                      icon: Icon(Icons.check_circle_outline, size: 20.sp),
                    ),
                    Tab(
                      text: 'Top Doctors (Cancelled)',
                      icon: Icon(Icons.cancel_outlined, size: 20.sp),
                    ),
                    Tab(
                      text: 'Patients with Most Cancellations',
                      icon: Icon(Icons.person_off_outlined, size: 20.sp),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Top Doctors by Completed Appointments
                      _buildTopDoctorsByCompletedTab(context, state),

                      // Top Doctors by Cancelled Appointments
                      _buildTopDoctorsByCancelledTab(context, state),

                      // Patients with Most Cancellations
                      _buildPatientsWithCancellationsTab(context, state),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopDoctorsByCompletedTab(
    BuildContext context,
    DashboardState state,
  ) {
    final isLoading = state is TopDoctorsByCompletedAppointmentsLoading;
    final List<DoctorStatistics> doctors =
        state is TopDoctorsByCompletedAppointmentsLoaded ? state.doctors : [];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: DoctorStatsTable(
        doctors: doctors,
        isLoading: isLoading,
        onRowTap: (doctor) {
          // Navigate to doctor details or show modal with details
          _showDoctorDetails(context, doctor);
        },
      ),
    );
  }

  Widget _buildTopDoctorsByCancelledTab(
    BuildContext context,
    DashboardState state,
  ) {
    final isLoading = state is TopDoctorsByCancelledAppointmentsLoading;
    final List<DoctorStatistics> doctors =
        state is TopDoctorsByCancelledAppointmentsLoaded ? state.doctors : [];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: DoctorStatsTable(
        doctors: doctors,
        isLoading: isLoading,
        onRowTap: (doctor) {
          // Navigate to doctor details or show modal with details
          _showDoctorDetails(context, doctor);
        },
      ),
    );
  }

  Widget _buildPatientsWithCancellationsTab(
    BuildContext context,
    DashboardState state,
  ) {
    final isLoading = state is TopPatientsByCancelledAppointmentsLoading;
    final List<PatientStatistics> patients =
        state is TopPatientsByCancelledAppointmentsLoaded ? state.patients : [];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: PatientStatsTable(
        patients: patients,
        isLoading: isLoading,
        onRowTap: (patient) {
          // Navigate to patient details or show modal with details
          _showPatientDetails(context, patient);
        },
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, DoctorStatistics doctor) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Doctor: ${doctor.name}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('Email', style: TextStyle(fontSize: 16.sp)),
                    subtitle: Text(
                      doctor.email,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.email, size: 24.sp),
                  ),
                  ListTile(
                    title: Text(
                      'Appointments',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      '${doctor.appointmentCount}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.calendar_today, size: 24.sp),
                  ),
                  ListTile(
                    title: Text(
                      'Completion Rate',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      '${(doctor.completionRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.percent, size: 24.sp),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.block, color: Colors.red, size: 20.sp),
                        label: Text(
                          'Ban Doctor',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        onPressed: () {
                          // TODO: Implement ban functionality
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${doctor.name} has been banned'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
    );
  }

  void _showPatientDetails(BuildContext context, PatientStatistics patient) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Patient: ${patient.name}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('Email', style: TextStyle(fontSize: 16.sp)),
                    subtitle: Text(
                      patient.email,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.email, size: 24.sp),
                  ),
                  ListTile(
                    title: Text(
                      'Total Appointments',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      '${patient.totalAppointments}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.calendar_today, size: 24.sp),
                  ),
                  ListTile(
                    title: Text(
                      'Cancelled Appointments',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      '${patient.cancelledAppointments}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    leading: Icon(Icons.cancel, size: 24.sp),
                  ),
                  ListTile(
                    title: Text(
                      'Cancellation Rate',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      '${(patient.cancellationRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:
                            patient.cancellationRate > 0.3 ? Colors.red : null,
                      ),
                    ),
                    leading: Icon(Icons.percent, size: 24.sp),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.block, color: Colors.red, size: 20.sp),
                        label: Text(
                          'Flag Account',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        onPressed: () {
                          // TODO: Implement flag functionality
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${patient.name} has been flagged'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
    );
  }
}
