import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/appointment_entity.dart';
import 'document_viewer_widget.dart';

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
  final int documentCount;
  final VoidCallback? onViewDocuments;

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
    this.documentCount = 0,
    this.onViewDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar with gradient
            Container(
              height: 4.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(),
                    _getStatusColor().withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  // Header: Date/Time and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date/Time with modern chips
                      Row(
                        children: [
                          _buildDateTimeChip(
                            icon: Icons.calendar_month_rounded,
                            text: _formatDate(appointment.appointmentDate),
                          ),
                          SizedBox(width: 8.w),
                          _buildDateTimeChip(
                            icon: Icons.schedule_rounded,
                            text: appointment.appointmentTime,
                          ),
                        ],
                      ),
                      // Status badge
                      _buildModernStatusBadge(),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Person info with modern avatar
                  Row(
                    children: [
                      _buildModernAvatar(),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPatientView
                                  ? 'Dr. ${appointment.doctorInfo?.fullName ?? 'Doctor'}'
                                  : appointment.patientInfo?.fullName ?? 'Patient',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            if (isPatientView && appointment.doctorInfo?.specialty != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 14.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      appointment.doctorInfo!.specialty,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Reason section
                  if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.notes_rounded,
                              size: 14.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reason for visit',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  appointment.reason!,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Document badge
                  if (documentCount > 0) ...[  
                    SizedBox(height: 10.h),
                    DocumentBadge(
                      count: documentCount,
                      onTap: onViewDocuments,
                    ),
                  ],

                  // Action buttons
                  if (_hasActions) ...[
                    SizedBox(height: 16.h),
                    _buildModernActionButtons(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: _getStatusColor()),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(),
            _getStatusColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        appointment.status.displayName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildModernAvatar() {
    final hasPhoto = isPatientView
        ? appointment.doctorInfo?.profilePhoto != null
        : appointment.patientInfo?.profilePhoto != null;
    final photoUrl = isPatientView
        ? appointment.doctorInfo?.profilePhoto
        : appointment.patientInfo?.profilePhoto;
    final name = isPatientView
        ? appointment.doctorInfo?.fullName ?? 'D'
        : appointment.patientInfo?.fullName ?? 'P';

    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        gradient: hasPhoto ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasPhoto && photoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
              ),
            )
          : _buildAvatarPlaceholder(name),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initials = _getInitials(name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case AppointmentStatus.completed:
        return AppColors.primary; // Blue
      case AppointmentStatus.cancelled:
        return const Color(0xFF9E9E9E); // Grey
      case AppointmentStatus.rejected:
        return const Color(0xFFE53935); // Red
      case AppointmentStatus.noShow:
        return const Color(0xFFE53935); // Red
    }
  }

  Widget _buildModernActionButtons() {
    if (isPatientView) {
      return Row(
        children: [
          if (onReschedule != null)
            Expanded(
              child: _buildModernButton(
                icon: Icons.schedule_rounded,
                label: 'Reschedule',
                onPressed: onReschedule!,
                isOutlined: true,
                color: AppColors.primary,
              ),
            ),
          if (onReschedule != null && onCancel != null) SizedBox(width: 10.w),
          if (onCancel != null)
            Expanded(
              child: _buildModernButton(
                icon: Icons.close_rounded,
                label: 'Cancel',
                onPressed: onCancel!,
                isOutlined: true,
                color: AppColors.error,
              ),
            ),
        ],
      );
    } else {
      // Doctor view actions
      return Column(
        children: [
          // Reschedule request actions
          if (_hasRescheduleRequest && (onApproveReschedule != null || onRejectReschedule != null)) ...[
            _buildRescheduleRequestBanner(),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (onApproveReschedule != null)
                  Expanded(
                    child: _buildModernButton(
                      icon: Icons.check_rounded,
                      label: 'Approve',
                      onPressed: onApproveReschedule!,
                      color: AppColors.success,
                    ),
                  ),
                if (onApproveReschedule != null && onRejectReschedule != null) 
                  SizedBox(width: 10.w),
                if (onRejectReschedule != null)
                  Expanded(
                    child: _buildModernButton(
                      icon: Icons.close_rounded,
                      label: 'Decline',
                      onPressed: onRejectReschedule!,
                      isOutlined: true,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Regular doctor actions
            Row(
              children: [
                if (onConfirm != null)
                  Expanded(
                    child: _buildModernButton(
                      icon: Icons.check_rounded,
                      label: 'Confirm',
                      onPressed: onConfirm!,
                      color: AppColors.success,
                    ),
                  ),
                if (onConfirm != null && onReject != null) SizedBox(width: 10.w),
                if (onReject != null)
                  Expanded(
                    child: _buildModernButton(
                      icon: Icons.close_rounded,
                      label: 'Reject',
                      onPressed: onReject!,
                      isOutlined: true,
                      color: AppColors.error,
                    ),
                  ),
                if (onComplete != null)
                  Expanded(
                    child: _buildModernButton(
                      icon: Icons.done_all_rounded,
                      label: 'Complete',
                      onPressed: onComplete!,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
            // Create Prescription Button
            if (onCreatePrescription != null) ...[
              SizedBox(height: 10.h),
              _buildModernButton(
                icon: Icons.receipt_long_rounded,
                label: 'Create Prescription',
                onPressed: onCreatePrescription!,
                isOutlined: true,
                color: AppColors.primary,
                fullWidth: true,
              ),
            ],
          ],
        ],
      );
    }
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isOutlined = false,
    required Color color,
    bool fullWidth = false,
  }) {
    final button = Container(
      height: 44.h,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : LinearGradient(
          colors: [color, color.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        boxShadow: isOutlined ? null : [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isOutlined ? color : Colors.white,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? button : button;
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
