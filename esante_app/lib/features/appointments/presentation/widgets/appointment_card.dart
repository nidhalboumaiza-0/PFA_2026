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
  final VoidCallback? onApproveReschedule;
  final VoidCallback? onRejectReschedule;
  final VoidCallback? onCreatePrescription;

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
    this.onApproveReschedule,
    this.onRejectReschedule,
    this.onCreatePrescription,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _getStatusBorderColor().withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _getStatusBorderColor().withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16.sp,
                        color: _getStatusBorderColor(),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatDate(appointment.appointmentDate),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusBorderColor(),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: _getStatusBorderColor(),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        appointment.appointmentTime,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusBorderColor(),
                        ),
                      ),
                    ],
                  ),
                  // Status badge
                  _buildStatusBadge(),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person info (doctor or patient)
                  Row(
                    children: [
                      _buildAvatar(),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPatientView
                                  ? appointment.doctorInfo?.fullName ?? 'Doctor'
                                  : appointment.patientInfo?.fullName ?? 'Patient',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            if (isPatientView && appointment.doctorInfo?.specialty != null)
                              Text(
                                appointment.doctorInfo!.specialty,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.grey400,
                                ),
                              )
                            else if (isPatientView && appointment.doctorInfo?.clinicName != null)
                              Text(
                                appointment.doctorInfo!.clinicName!,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.grey400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Reason if exists
                  if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.grey200.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16.sp,
                            color: AppColors.grey400,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              appointment.reason!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.grey500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasPhoto = isPatientView
        ? appointment.doctorInfo?.profilePhoto != null
        : appointment.patientInfo?.profilePhoto != null;
    final photoUrl = isPatientView
        ? appointment.doctorInfo?.profilePhoto
        : appointment.patientInfo?.profilePhoto;

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: hasPhoto && photoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  isPatientView ? Icons.medical_services : Icons.person,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
            )
          : Icon(
              isPatientView ? Icons.medical_services : Icons.person,
              color: AppColors.primary,
              size: 24.sp,
            ),
    );
  }

  Color _getStatusBorderColor() {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.cancelled:
        return AppColors.grey400;
      case AppointmentStatus.rejected:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.error;
    }
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
      return onConfirm != null ||
          onReject != null ||
          onComplete != null ||
          onReschedule != null ||
          onCancel != null ||
          onApproveReschedule != null ||
          onRejectReschedule != null ||
          onCreatePrescription != null;
    }
  }

  bool get _hasRescheduleRequest =>
      appointment.rescheduleRequest != null &&
      appointment.rescheduleRequest!.isPending;

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
      return Column(
        children: [
          // Reschedule request actions (if patient requested reschedule)
          if (_hasRescheduleRequest && (onApproveReschedule != null || onRejectReschedule != null)) ...[
            _buildRescheduleRequestBanner(),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (onApproveReschedule != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApproveReschedule,
                      icon: Icon(Icons.check, size: 18.sp),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                if (onApproveReschedule != null && onRejectReschedule != null) 
                  SizedBox(width: 8.w),
                if (onRejectReschedule != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRejectReschedule,
                      icon: Icon(Icons.close, size: 18.sp),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Regular doctor actions
            Row(
              children: [
                // Confirm/Reject for pending appointments
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
                // Complete action
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
            ),
            // Create Prescription Button (for Confirmed/Completed appointments)
            if (onCreatePrescription != null) ...[
              SizedBox(height: 8.h),
              CustomButton(
                text: 'Create Prescription',
                onPressed: onCreatePrescription,
                icon: Icons.receipt_long,
                isOutlined: true,
              ),
            ],
            // Secondary actions (reschedule/cancel) for confirmed appointments
            if ((onReschedule != null || onCancel != null) && onConfirm == null && onComplete == null) ...[
              SizedBox(height: 8.h),
              Row(
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
                  if (onReschedule != null && onCancel != null) SizedBox(width: 8.w),
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
              ),
            ],
          ],
        ],
      );
    }
  }

  Widget _buildRescheduleRequestBanner() {
    final request = appointment.rescheduleRequest!;
    final dateStr = request.requestedDate != null
        ? '${request.requestedDate!.day}/${request.requestedDate!.month}/${request.requestedDate!.year}'
        : 'Unknown';
    final timeStr = request.requestedTime ?? 'Unknown';

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppColors.warning, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reschedule Request',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'New: $dateStr at $timeStr',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textPrimaryStatic,
                  ),
                ),
                if (request.reason != null && request.reason!.isNotEmpty)
                  Text(
                    'Reason: ${request.reason}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
