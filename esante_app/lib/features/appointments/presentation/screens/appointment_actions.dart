import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../doctors/domain/usecases/submit_review_usecase.dart';
import '../../../doctors/domain/usecases/get_appointment_review_usecase.dart';
import '../../../doctors/presentation/screens/doctor_detail_screen.dart';
import '../../../prescriptions/presentation/screens/create_prescription_screen.dart';
import '../../../prescriptions/presentation/screens/my_prescriptions_screen.dart';
import 'referral_booking_screen.dart';

/// Widget showing patient-specific actions for an appointment
class PatientAppointmentActions extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback? onAppointmentChanged;

  const PatientAppointmentActions({
    super.key,
    required this.appointment,
    this.onAppointmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        SizedBox(height: 12.h),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              // Rate Doctor - only for completed appointments
              if (appointment.status == AppointmentStatus.completed)
                _ActionTile(
                  icon: Icons.star_outline,
                  iconColor: Colors.amber,
                  title: 'Rate & Review Doctor',
                  subtitle: 'Share your experience',
                  onTap: () => _showRatingDialog(context),
                ),
              
              // View Prescription - for completed appointments
              if (appointment.status == AppointmentStatus.completed) ...[
                Divider(height: 1, indent: 56.w),
                _ActionTile(
                  icon: Icons.medication_outlined,
                  iconColor: AppColors.success,
                  title: 'View Prescription',
                  subtitle: 'See medications prescribed',
                  onTap: () => context.pushPage(const MyPrescriptionsScreen()),
                ),
              ],
              
              // View Doctor Profile - always available
              if (appointment.status == AppointmentStatus.completed)
                Divider(height: 1, indent: 56.w),
              _ActionTile(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: 'View Doctor Profile',
                subtitle: 'See ratings, reviews & more',
                onTap: () => context.pushPage(
                  DoctorDetailScreen(doctorId: appointment.doctorId),
                ),
              ),
              
              // Book Again - for completed/cancelled appointments
              if (appointment.status.isFinal) ...[
                Divider(height: 1, indent: 56.w),
                _ActionTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.info,
                  title: 'Book Again',
                  subtitle: 'Schedule new appointment with this doctor',
                  onTap: () => context.pushPage(
                    DoctorDetailScreen(doctorId: appointment.doctorId),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.touch_app, color: AppColors.primary, size: 22.sp),
        SizedBox(width: 8.w),
        AppBodyText(
          text: 'Actions',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  void _showRatingDialog(BuildContext context) {
    // Check if already reviewed first
    _checkExistingReview(context, appointment.id).then((exists) {
      if (exists && context.mounted) {
        AppSnackBar.info(context, 'You have already reviewed this appointment');
        return;
      }
      
      if (!context.mounted) return;
      
      RatingDialog.show(
        context,
        title: 'Rate Your Experience',
        doctorName: appointment.doctorInfo?.fullName ?? 'the doctor',
        onSubmit: (rating, comment) async {
          final submitReviewUseCase = sl<SubmitReviewUseCase>();
          final result = await submitReviewUseCase(SubmitReviewParams(
            appointmentId: appointment.id,
            rating: rating,
            comment: comment,
          ));

          result.fold(
            (failure) {
              throw Exception(failure.message);
            },
            (review) {
              AppSnackBar.success(context, 'Thank you for your review!');
              onAppointmentChanged?.call();
            },
          );
        },
      );
    });
  }

  Future<bool> _checkExistingReview(BuildContext context, String appointmentId) async {
    try {
      final getReviewUseCase = sl<GetAppointmentReviewUseCase>();
      final result = await getReviewUseCase(GetAppointmentReviewParams(
        appointmentId: appointmentId,
      ));
      return result.fold(
        (_) => false,
        (review) => review != null,
      );
    } catch (e) {
      return false;
    }
  }
}

/// Widget showing doctor-specific actions for an appointment
class DoctorAppointmentActions extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback? onAppointmentChanged;

  const DoctorAppointmentActions({
    super.key,
    required this.appointment,
    this.onAppointmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        SizedBox(height: 12.h),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              // Create Prescription - for confirmed/completed appointments
              if (appointment.status == AppointmentStatus.confirmed ||
                  appointment.status == AppointmentStatus.completed)
                _ActionTile(
                  icon: Icons.medication_outlined,
                  iconColor: AppColors.success,
                  title: 'Create Prescription',
                  subtitle: 'Write medications for this patient',
                  onTap: () => _createPrescription(context),
                ),
              
              // Mark as Complete - for confirmed appointments
              if (appointment.status == AppointmentStatus.confirmed) ...[
                Divider(height: 1, indent: 56.w),
                _ActionTile(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  title: 'Mark as Complete',
                  subtitle: 'End this consultation',
                  onTap: () => _markAsComplete(context),
                ),
              ],
              
              // Refer to Specialist - for confirmed/completed
              if (appointment.status == AppointmentStatus.confirmed ||
                  appointment.status == AppointmentStatus.completed) ...[
                Divider(height: 1, indent: 56.w),
                _ActionTile(
                  icon: Icons.swap_horiz,
                  iconColor: AppColors.info,
                  title: 'Refer to Specialist',
                  subtitle: 'Send patient to another doctor',
                  onTap: () => _referToSpecialist(context),
                ),
              ],
              
              // Add Notes - always for doctor
              if (appointment.status == AppointmentStatus.confirmed ||
                  appointment.status == AppointmentStatus.completed)
                Divider(height: 1, indent: 56.w),
              _ActionTile(
                icon: Icons.note_add_outlined,
                iconColor: AppColors.warning,
                title: 'Add Medical Notes',
                subtitle: 'Record observations & findings',
                onTap: () => _addMedicalNotes(context),
              ),

              // View Patient History
              Divider(height: 1, indent: 56.w),
              _ActionTile(
                icon: Icons.history,
                iconColor: AppColors.grey600,
                title: 'View Patient History',
                subtitle: 'Past appointments & records',
                onTap: () => _viewPatientHistory(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.touch_app, color: AppColors.primary, size: 22.sp),
        SizedBox(width: 8.w),
        AppBodyText(
          text: 'Actions',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  void _createPrescription(BuildContext context) {
    context.pushPage(
      CreatePrescriptionScreen(
        consultationId: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        patientName: appointment.patientInfo?.fullName ?? 'Patient',
      ),
      transition: NavTransition.slideUp,
    );
  }

  void _markAsComplete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Complete Appointment',
      message: 'Are you sure you want to mark this appointment as completed?',
      confirmText: 'Complete',
      cancelText: 'Cancel',
      type: DialogType.info,
    );
    
    if (confirmed == true && context.mounted) {
      // TODO: Call complete appointment API
      AppSnackBar.success(context, 'Appointment marked as complete');
      onAppointmentChanged?.call();
      Navigator.pop(context); // Go back to list
    }
  }

  void _referToSpecialist(BuildContext context) {
    context.pushPage(
      ReferralBookingScreen(
        preselectedPatient: appointment.patientInfo,
        referralId: null,
      ),
      transition: NavTransition.slideUp,
    );
  }

  void _addMedicalNotes(BuildContext context) {
    final notesController = TextEditingController(text: appointment.notes);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.note_add, color: AppColors.primary, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  AppBodyText(
                    text: 'Medical Notes',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                controller: notesController,
                hintText: 'Enter medical observations, diagnosis, recommendations...',
                maxLines: 5,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      isOutlined: true,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomButton(
                      text: 'Save Notes',
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        // TODO: Save notes to backend
                        AppSnackBar.success(context, 'Notes saved');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPatientHistory(BuildContext context) {
    // TODO: Navigate to patient history screen
    AppSnackBar.info(context, 'Patient history coming soon');
  }
}

/// Reusable action tile widget
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: iconColor, size: 24.sp),
      ),
      title: AppBodyText(
        text: title,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
      subtitle: AppSmallText(
        text: subtitle,
        fontSize: 12.sp,
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}
