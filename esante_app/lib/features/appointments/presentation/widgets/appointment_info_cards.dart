import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/appointment_entity.dart';

/// Status banner widget showing appointment status
class AppointmentStatusBanner extends StatelessWidget {
  final AppointmentEntity appointment;

  const AppointmentStatusBanner({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getStatusColor(appointment.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: _getStatusColor(appointment.status),
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBodyText(
                  text: appointment.status.displayName,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(appointment.status),
                ),
                SizedBox(height: 4.h),
                AppSmallText(
                  text: _getStatusDescription(appointment),
                  fontSize: 13.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.rejected:
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.noShow:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.rejected:
        return Icons.block;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getStatusDescription(AppointmentEntity appointment) {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return 'Waiting for doctor confirmation';
      case AppointmentStatus.confirmed:
        return 'Your appointment is confirmed';
      case AppointmentStatus.rejected:
        return 'The doctor was unable to accept this appointment';
      case AppointmentStatus.cancelled:
        return 'This appointment has been cancelled';
      case AppointmentStatus.completed:
        return 'This appointment has been completed';
      case AppointmentStatus.noShow:
        return 'Patient did not attend this appointment';
    }
  }
}

/// Card showing person info (doctor for patient, patient for doctor)
class PersonInfoCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool isPatientView;
  final VoidCallback? onTap;

  const PersonInfoCard({
    super.key,
    required this.appointment,
    required this.isPatientView,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = isPatientView 
        ? 'Dr. ${appointment.doctorInfo?.fullName ?? 'Unknown'}'
        : appointment.patientInfo?.fullName ?? 'Unknown Patient';
    final subtitle = isPatientView
        ? appointment.doctorInfo?.specialty ?? 'Specialist'
        : 'Patient';
    final photo = isPatientView
        ? appointment.doctorInfo?.profilePhoto
        : appointment.patientInfo?.profilePhoto;
    final rating = isPatientView ? appointment.doctorInfo?.rating : null;
    final reviewCount = isPatientView ? appointment.doctorInfo?.reviewCount : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: isPatientView ? onTap : null,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Icon(
                        isPatientView ? Icons.medical_services : Icons.person,
                        size: 30.sp,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBodyText(
                      text: name,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 4.h),
                    AppSmallText(
                      text: subtitle,
                      fontSize: 14.sp,
                    ),
                    if (isPatientView && rating != null) ...[
                      SizedBox(height: 6.h),
                      RatingBadge(
                        rating: rating,
                        reviewCount: reviewCount,
                      ),
                    ],
                  ],
                ),
              ),
              if (isPatientView)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.grey400,
                  size: 24.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing date and time information
class DateTimeCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const DateTimeCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.calendar_today,
              iconColor: AppColors.primary,
              label: 'Date',
              value: dateFormat.format(appointment.appointmentDate),
            ),
            Divider(height: 24.h),
            _buildInfoRow(
              icon: Icons.access_time,
              iconColor: AppColors.info,
              label: 'Time',
              value: appointment.appointmentTime,
            ),
            Divider(height: 24.h),
            _buildInfoRow(
              icon: Icons.timelapse,
              iconColor: AppColors.warning,
              label: 'Duration',
              value: '${appointment.duration} minutes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card showing reason for visit
class ReasonCard extends StatelessWidget {
  final String reason;

  const ReasonCard({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Reason for Visit',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing referral information
class ReferralInfoCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const ReferralInfoCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.info.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.info, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Referral Information',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (appointment.referringDoctorInfo != null)
              Text(
                'Referred by Dr. ${appointment.referringDoctorInfo!.fullName}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card showing reschedule information
class RescheduleInfoCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const RescheduleInfoCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.warning.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Rescheduled',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (appointment.previousDate != null)
              Text(
                'Originally scheduled: ${DateFormat('MMM d, yyyy').format(appointment.previousDate!)} at ${appointment.previousTime ?? ''}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
            if (appointment.rescheduleReason != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Reason: ${appointment.rescheduleReason}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card showing cancellation information
class CancellationCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const CancellationCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Cancelled',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (appointment.cancelledBy != null)
              Text(
                'Cancelled by: ${appointment.cancelledBy == 'patient' ? 'Patient' : 'Doctor'}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
            if (appointment.cancellationReason != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Reason: ${appointment.cancellationReason}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
            ],
            if (appointment.cancelledAt != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Cancelled on: ${DateFormat('MMM d, yyyy HH:mm').format(appointment.cancelledAt!)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card showing rejection information
class RejectionCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const RejectionCard({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: AppColors.error, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Rejected by Doctor',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (appointment.rejectionReason != null) ...[
              SizedBox(height: 12.h),
              Text(
                'Reason: ${appointment.rejectionReason}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card showing notes
class NotesCard extends StatelessWidget {
  final String notes;

  const NotesCard({
    super.key,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              notes,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
