import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/appointment_entity.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool isPatientView;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isPatientView = true,
    this.onTap,
    this.onCancel,
    this.onReschedule,
    this.onConfirm,
    this.onReject,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Person info (doctor or patient)
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          isPatientView ? Icons.person : Icons.person_outline,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              text: isPatientView
                                  ? appointment.doctorInfo?.fullName ??
                                      'Dr. Unknown'
                                  : appointment.patientInfo?.fullName ??
                                      'Unknown Patient',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isPatientView &&
                                appointment.doctorInfo?.specialty != null)
                              AppBodyText(
                                text: appointment.doctorInfo!.specialty,
                                color: AppColors.grey400,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _buildStatusBadge(),
              ],
            ),
            SizedBox(height: 16.h),

            // Date and Time
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _formatDate(appointment.appointmentDate),
                  ),
                  SizedBox(width: 24.w),
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: appointment.appointmentTime,
                  ),
                ],
              ),
            ),

            // Reason if exists
            if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16.sp,
                    color: AppColors.grey400,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppSmallText(
                      text: appointment.reason!,
                      color: AppColors.grey400,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (_hasActions) ...[
              SizedBox(height: 16.h),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text = appointment.status.displayName;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        break;
      case AppointmentStatus.confirmed:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        break;
      case AppointmentStatus.completed:
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        break;
      case AppointmentStatus.cancelled:
        bgColor = AppColors.grey300.withValues(alpha: 0.5);
        textColor = AppColors.grey400;
        break;
      case AppointmentStatus.rejected:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
      case AppointmentStatus.noShow:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSmallText(
              text: label,
              color: AppColors.grey400,
            ),
            AppBodyText(
              text: value,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ],
    );
  }

  bool get _hasActions {
    if (isPatientView) {
      return onCancel != null || onReschedule != null;
    } else {
      return onConfirm != null || onReject != null || onComplete != null;
    }
  }

  Widget _buildActionButtons() {
    if (isPatientView) {
      return Row(
        children: [
          if (onReschedule != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReschedule,
                icon: Icon(Icons.schedule, size: 18.sp),
                label: const Text('Reschedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
          if (onReschedule != null && onCancel != null) SizedBox(width: 12.w),
          if (onCancel != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: Icon(Icons.close, size: 18.sp),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
        ],
      );
    } else {
      // Doctor view actions
      return Row(
        children: [
          if (onConfirm != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: Icon(Icons.check, size: 18.sp),
                label: const Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
          if (onConfirm != null && onReject != null) SizedBox(width: 8.w),
          if (onReject != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: Icon(Icons.close, size: 18.sp),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
          if (onComplete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onComplete,
                icon: Icon(Icons.done_all, size: 18.sp),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
        ],
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
