import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../bloc/doctor/doctor_appointment_bloc.dart';
import '../widgets/appointment_card.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  final bool showBackButton;
  
  const DoctorAppointmentsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use singleton BLoC from DI for real-time WebSocket updates
    final bloc = sl<DoctorAppointmentBloc>();
    // Load appointments when screen opens
    bloc.add(const LoadDoctorAppointments());
    
    return BlocProvider.value(
      value: bloc,
      child: _DoctorAppointmentsView(showBackButton: showBackButton),
    );
  }
}

class _DoctorAppointmentsView extends StatefulWidget {
  final bool showBackButton;
  
  const _DoctorAppointmentsView({
    this.showBackButton = true,
  });

  @override
  State<_DoctorAppointmentsView> createState() => _DoctorAppointmentsViewState();
}

class _DoctorAppointmentsViewState extends State<_DoctorAppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Appointments',
        showBackButton: widget.showBackButton,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.grey300.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey400,
              labelStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Requests'),
                Tab(text: 'Upcoming'),
                Tab(text: 'History'),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Content
          Expanded(
            child: BlocConsumer<DoctorAppointmentBloc, DoctorAppointmentState>(
              listener: (context, state) {
                if (state is AppointmentConfirmed) {
                  AppSnackBar.success(context, 'Appointment confirmed');
                  _refreshData(context);
                } else if (state is AppointmentRejected) {
                  AppSnackBar.success(context, 'Appointment rejected');
                  _refreshData(context);
                } else if (state is AppointmentCompleted) {
                  AppSnackBar.success(context, 'Appointment completed');
                  _refreshData(context);
                } else if (state is DoctorAppointmentError) {
                  AppSnackBar.error(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is DoctorAppointmentsLoading ||
                    state is AppointmentRequestsLoading ||
                    state is AppointmentActionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsTab(context),
                    _buildUpcomingTab(context),
                    _buildHistoryTab(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData(BuildContext context) {
    context.read<DoctorAppointmentBloc>().add(const LoadDoctorAppointments());
  }

  Widget _buildRequestsTab(BuildContext context) {
    return BlocBuilder<DoctorAppointmentBloc, DoctorAppointmentState>(
      builder: (context, state) {
        // Load requests if not already loaded
        if (state is! AppointmentRequestsLoaded) {
          context.read<DoctorAppointmentBloc>().add(
                const LoadAppointmentRequests(),
              );
          return const Center(child: CircularProgressIndicator());
        }

        final requests = state.requests.where((r) => r.isPending).toList();

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox,
            title: 'No pending requests',
            subtitle: 'New appointment requests will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.r),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final appointment = requests[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AppointmentCard(
                appointment: appointment,
                isPatientView: false,
                onConfirm: () => _confirmAppointment(context, appointment),
                onReject: () => _showRejectDialog(context, appointment),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingTab(BuildContext context) {
    return BlocBuilder<DoctorAppointmentBloc, DoctorAppointmentState>(
      builder: (context, state) {
        if (state is! DoctorAppointmentsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final upcoming = state.upcomingAppointments
            .where((a) => a.isConfirmed)
            .toList();

        if (upcoming.isEmpty) {
          return _buildEmptyState(
            icon: Icons.calendar_today,
            title: 'No upcoming appointments',
            subtitle: 'Confirmed appointments will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(context),
          child: ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final appointment = upcoming[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AppointmentCard(
                  appointment: appointment,
                  isPatientView: false,
                  onComplete: () => _showCompleteDialog(context, appointment),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return BlocBuilder<DoctorAppointmentBloc, DoctorAppointmentState>(
      builder: (context, state) {
        if (state is! DoctorAppointmentsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = state.appointments
            .where((a) => a.isFinal)
            .toList();

        if (history.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No appointment history',
            subtitle: 'Completed appointments will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(context),
          child: ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final appointment = history[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AppointmentCard(
                  appointment: appointment,
                  isPatientView: false,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: AppColors.grey300),
          SizedBox(height: 16.h),
          AppTitle(text: title, fontSize: 18.sp),
          SizedBox(height: 8.h),
          AppSubtitle(
            text: subtitle,
            fontSize: 14.sp,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmAppointment(BuildContext context, AppointmentEntity appointment) {
    context.read<DoctorAppointmentBloc>().add(
          ConfirmAppointmentRequest(appointmentId: appointment.id),
        );
  }

  void _showRejectDialog(BuildContext context, AppointmentEntity appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this appointment?'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Please provide a reason',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                AppSnackBar.warning(context, 'Please provide a reason');
                return;
              }
              Navigator.pop(dialogContext);
              context.read<DoctorAppointmentBloc>().add(
                    RejectAppointmentRequest(
                      appointmentId: appointment.id,
                      reason: reasonController.text.trim(),
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, AppointmentEntity appointment) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mark this appointment as completed?'),
            SizedBox(height: 16.h),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about the visit',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DoctorAppointmentBloc>().add(
                    CompleteAppointmentAction(
                      appointmentId: appointment.id,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
