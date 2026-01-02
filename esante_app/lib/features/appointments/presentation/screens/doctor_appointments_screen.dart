import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../prescriptions/presentation/screens/create_prescription_screen.dart';
import '../bloc/doctor/doctor_appointment_bloc.dart';
import '../widgets/appointment_card.dart';
import '../widgets/doctor_reschedule_dialog.dart';
import 'appointment_details_page.dart';
import 'referral_booking_screen.dart';

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
    // Load BOTH appointments and requests when screen opens
    bloc.add(const LoadDoctorAppointments());
    bloc.add(const LoadAppointmentRequests());
    
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
  
  // Cache states to survive state changes from other screens (shared singleton BLoC)
  DoctorAppointmentsLoaded? _cachedAppointmentsState;
  AppointmentRequestsLoaded? _cachedRequestsState;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReferralBookingScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(
          'Refer Patient',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
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
              listenWhen: (previous, current) {
                // Listen to action results and errors
                return current is AppointmentConfirmed ||
                    current is AppointmentRejected ||
                    current is AppointmentCompleted ||
                    current is AppointmentRescheduled ||
                    current is AppointmentCancelledByDoctor ||
                    current is RescheduleApproved ||
                    current is RescheduleRejected ||
                    current is DoctorAppointmentError;
              },
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
                } else if (state is AppointmentRescheduled) {
                  AppSnackBar.success(context, 'Appointment rescheduled successfully');
                  _refreshData(context);
                } else if (state is AppointmentCancelledByDoctor) {
                  AppSnackBar.success(context, 'Appointment cancelled');
                  _refreshData(context);
                } else if (state is RescheduleApproved) {
                  AppSnackBar.success(context, 'Reschedule request approved');
                  _refreshData(context);
                } else if (state is RescheduleRejected) {
                  AppSnackBar.success(context, 'Reschedule request declined');
                  _refreshData(context);
                } else if (state is DoctorAppointmentError) {
                  AppSnackBar.error(context, state.message);
                }
              },
              buildWhen: (previous, current) {
                // Only rebuild on states relevant to this screen
                return current is DoctorAppointmentInitial ||
                    current is DoctorAppointmentsLoading ||
                    current is DoctorAppointmentsLoaded ||
                    current is AppointmentRequestsLoading ||
                    current is AppointmentRequestsLoaded ||
                    current is AppointmentActionLoading ||
                    current is DoctorAppointmentError;
              },
              builder: (context, state) {
                // Cache states when loaded
                if (state is DoctorAppointmentsLoaded) {
                  _cachedAppointmentsState = state;
                }
                if (state is AppointmentRequestsLoaded) {
                  _cachedRequestsState = state;
                }
                
                if (state is DoctorAppointmentsLoading ||
                    state is AppointmentRequestsLoading ||
                    state is AppointmentActionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show content if we have data (either current or cached)
                if (state is DoctorAppointmentsLoaded || 
                    state is AppointmentRequestsLoaded ||
                    _cachedAppointmentsState != null ||
                    _cachedRequestsState != null) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsTab(context),
                      _buildUpcomingTab(context),
                      _buildHistoryTab(context),
                    ],
                  );
                }
                
                // Default loading for initial state
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData(BuildContext context) {
    context.read<DoctorAppointmentBloc>().add(const LoadDoctorAppointments());
    context.read<DoctorAppointmentBloc>().add(const LoadAppointmentRequests());
  }

  Widget _buildRequestsTab(BuildContext context) {
    return BlocBuilder<DoctorAppointmentBloc, DoctorAppointmentState>(
      buildWhen: (previous, current) {
        return current is AppointmentRequestsLoading ||
            current is AppointmentRequestsLoaded ||
            current is DoctorAppointmentError;
      },
      builder: (context, state) {
        // Cache state when loaded
        if (state is AppointmentRequestsLoaded) {
          _cachedRequestsState = state;
        }
        
        // Load requests if not already loaded and no cache
        if (state is! AppointmentRequestsLoaded && _cachedRequestsState == null) {
          context.read<DoctorAppointmentBloc>().add(
                const LoadAppointmentRequests(),
              );
          return const Center(child: CircularProgressIndicator());
        }
        
        // Use current state or cached state
        final requestsState = state is AppointmentRequestsLoaded ? state : _cachedRequestsState;
        if (requestsState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = requestsState.requests.where((r) => r.isPending).toList();

        if (requests.isEmpty) {
          return _buildEmptyState(
            lottieAsset: AppAssets.waitingAppointmentLottie,
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
                onTap: () => _showAppointmentDetails(context, appointment),
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
      buildWhen: (previous, current) {
        return current is DoctorAppointmentsLoading ||
            current is DoctorAppointmentsLoaded ||
            current is DoctorAppointmentError;
      },
      builder: (context, state) {
        // Cache state when loaded
        if (state is DoctorAppointmentsLoaded) {
          _cachedAppointmentsState = state;
        }
        
        // Load appointments if not already loaded and no cache
        if (state is! DoctorAppointmentsLoaded && _cachedAppointmentsState == null) {
          context.read<DoctorAppointmentBloc>().add(const LoadDoctorAppointments());
          return const Center(child: CircularProgressIndicator());
        }
        
        // Use current state or cached state
        final appointmentsState = state is DoctorAppointmentsLoaded ? state : _cachedAppointmentsState;
        if (appointmentsState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final upcoming = appointmentsState.upcomingAppointments
            .where((a) => a.isConfirmed)
            .toList();

        if (upcoming.isEmpty) {
          return _buildEmptyState(
            lottieAsset: AppAssets.consultationLottie,
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
              final hasRescheduleRequest = appointment.rescheduleRequest != null &&
                  appointment.rescheduleRequest!.isPending;
              
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AppointmentCard(
                  appointment: appointment,
                  isPatientView: false,
                  onTap: () => _showAppointmentDetails(context, appointment),
                  onComplete: () => _showCompleteDialog(context, appointment),
                  onReschedule: hasRescheduleRequest 
                      ? null 
                      : () => _showDoctorRescheduleDialog(context, appointment),
                  onCancel: hasRescheduleRequest 
                      ? null 
                      : () => _showDoctorCancelDialog(context, appointment),
                  onApproveReschedule: hasRescheduleRequest
                      ? () => _approveReschedule(context, appointment)
                      : null,
                  onRejectReschedule: hasRescheduleRequest
                      ? () => _showRejectRescheduleDialog(context, appointment)
                      : null,
                  onCreatePrescription: () => context.pushPage(
                    CreatePrescriptionScreen(
                      consultationId: appointment.id,
                      patientId: appointment.patientId,
                      doctorId: appointment.doctorId,
                      patientName: appointment.patientInfo?.fullName ?? 'Patient',
                    ),
                    transition: NavTransition.slideUp,
                  ),
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
      buildWhen: (previous, current) {
        return current is DoctorAppointmentsLoading ||
            current is DoctorAppointmentsLoaded ||
            current is DoctorAppointmentError;
      },
      builder: (context, state) {
        // Cache state when loaded
        if (state is DoctorAppointmentsLoaded) {
          _cachedAppointmentsState = state;
        }
        
        // Load appointments if not already loaded and no cache
        if (state is! DoctorAppointmentsLoaded && _cachedAppointmentsState == null) {
          context.read<DoctorAppointmentBloc>().add(const LoadDoctorAppointments());
          return const Center(child: CircularProgressIndicator());
        }
        
        // Use current state or cached state
        final appointmentsState = state is DoctorAppointmentsLoaded ? state : _cachedAppointmentsState;
        if (appointmentsState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = appointmentsState.appointments
            .where((a) => a.isFinal)
            .toList();

        if (history.isEmpty) {
          return _buildEmptyState(
            lottieAsset: AppAssets.prescriptionLottie,
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
                  onTap: () => _showAppointmentDetails(context, appointment),
                  onCreatePrescription: appointment.status == AppointmentStatus.completed
                      ? () => context.pushPage(
                            CreatePrescriptionScreen(
                              consultationId: appointment.id,
                              patientId: appointment.patientId,
                              doctorId: appointment.doctorId,
                              patientName: appointment.patientInfo?.fullName ?? 'Patient',
                            ),
                            transition: NavTransition.slideUp,
                          )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String lottieAsset,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              lottieAsset,
              width: 180.w,
              height: 180.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            AppTitle(text: title, fontSize: 18.sp),
            SizedBox(height: 8.h),
            AppSubtitle(
              text: subtitle,
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  void _showDoctorRescheduleDialog(BuildContext context, AppointmentEntity appointment) {
    DoctorRescheduleDialog.show(context, appointment: appointment);
  }

  void _showDoctorCancelDialog(BuildContext context, AppointmentEntity appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.grey500, size: 18.sp),
                SizedBox(width: 8.w),
                AppBodyText(
                  text: appointment.patientInfo?.fullName ?? 'Patient',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            SizedBox(height: 16.h),
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
              context.read<DoctorAppointmentBloc>().add(
                    CancelByDoctor(
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

  void _approveReschedule(BuildContext context, AppointmentEntity appointment) {
    context.read<DoctorAppointmentBloc>().add(
          ApprovePatientReschedule(appointmentId: appointment.id),
        );
  }

  void _showRejectRescheduleDialog(BuildContext context, AppointmentEntity appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline Reschedule Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to decline this reschedule request?'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Provide a reason for declining',
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
              Navigator.pop(dialogContext);
              context.read<DoctorAppointmentBloc>().add(
                    RejectPatientReschedule(
                      appointmentId: appointment.id,
                      reason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentEntity appointment) {
    context.pushPage(
      AppointmentDetailsPage(
        appointment: appointment,
        isPatientView: false,
        onAppointmentChanged: () {
          // Refresh appointments when something changes
          _refreshData(this.context);
        },
      ),
    );
  }
}
