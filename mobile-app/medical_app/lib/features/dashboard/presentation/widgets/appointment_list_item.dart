import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class AppointmentListItem extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const AppointmentListItem({
    Key? key,
    required this.appointment,
    this.onTap,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final formattedDate = DateFormat('dd/MM/yyyy').format(appointment.appointmentDate);
    final formattedTime = DateFormat('HH:mm').format(appointment.appointmentDate);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              height: 40.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    appointment.appointmentType ?? 'Consultation',
                    style: GoogleFonts.raleway(
                      fontSize: 13.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.colorScheme.surface : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: isDarkMode ? theme.textTheme.bodySmall?.color : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 