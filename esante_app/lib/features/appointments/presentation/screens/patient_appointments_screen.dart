import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../bloc/patient/patient_appointment_bloc.dart';
import '../widgets/appointment_card.dart';
import '../widgets/reschedule_dialog.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  final bool showBackButton;
  
  const PatientAppointmentsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use singleton BLoC from DI for real-time WebSocket updates
    final bloc = sl<PatientAppointmentBloc>();
    // Load appointments when screen opens
    bloc.add(const LoadPatientAppointments());
    
    return BlocProvider.value(
      value: bloc,
      child: _PatientAppointmentsView(showBackButton: showBackButton),
    );
  }
}

class _PatientAppointmentsView extends StatefulWidget {
  final bool showBackButton;
  
  const _PatientAppointmentsView({
    this.showBackButton = true,
  });

  @override
  State<_PatientAppointmentsView> createState() => _PatientAppointmentsViewState();
}

class _PatientAppointmentsViewState extends State<_PatientAppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Content
          Expanded(
            child: BlocConsumer<PatientAppointmentBloc, PatientAppointmentState>(
              listener: (context, state) {
                if (state is AppointmentCancelled) {
                  AppSnackBar.success(context, 'Appointment cancelled');
                  context.read<PatientAppointmentBloc>().add(
                        const LoadPatientAppointments(),
                      );
                } else if (state is RescheduleRequestSent) {
                  AppSnackBar.success(context, 'Reschedule request sent');
                  context.read<PatientAppointmentBloc>().add(
                        const LoadPatientAppointments(),
                      );
                } else if (state is PatientAppointmentError) {
                  AppSnackBar.error(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is PatientAppointmentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PatientAppointmentsLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList(
                        context,
                        state.upcomingAppointments,
                        isUpcoming: true,
                      ),
                      _buildAppointmentsList(
                        context,
                        state.pastAppointments,
                        isUpcoming: false,
                      ),
                    ],
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                      SizedBox(height: 16.h),
                      const AppSubtitle(text: 'Failed to load appointments'),
                      SizedBox(height: 16.h),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          context.read<PatientAppointmentBloc>().add(
                                const LoadPatientAppointments(),
                              );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<AppointmentEntity> appointments, {
    required bool isUpcoming,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                isUpcoming
                    ? AppAssets.waitingAppointmentLottie
                    : AppAssets.prescriptionLottie,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24.h),
              AppTitle(
                text: isUpcoming ? 'No upcoming appointments' : 'No past appointments',
                fontSize: 18.sp,
              ),
              SizedBox(height: 8.h),
              AppSubtitle(
                text: isUpcoming
                    ? 'Book an appointment with a doctor'
                    : 'Your appointment history will appear here',
                fontSize: 14.sp,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PatientAppointmentBloc>().add(
              const LoadPatientAppointments(),
            );
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AppointmentCard(
              appointment: appointment,
              isPatientView: true,
              onCancel: appointment.canCancel
                  ? () => _showCancelDialog(context, appointment)
                  : null,
              onReschedule: appointment.canReschedule
                  ? () => _showRescheduleDialog(context, appointment)
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentEntity appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Please provide a reason',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                AppSnackBar.warning(context, 'Please provide a reason');
                return;
              }
              Navigator.pop(dialogContext);
              context.read<PatientAppointmentBloc>().add(
                    CancelPatientAppointment(
                      appointmentId: appointment.id,
                      reason: reasonController.text.trim(),
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, AppointmentEntity appointment) {
    RescheduleDialog.show(context, appointment: appointment);
  }
}
