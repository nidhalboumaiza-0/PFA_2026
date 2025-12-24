import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/translator.dart';
import '../../../../core/utils/app_colors.dart';

/// Dialog for rescheduling an appointment
/// Used by both doctors (direct reschedule) and patients (request reschedule)
class RescheduleDialog extends StatefulWidget {
  final String appointmentId;
  final DateTime currentDate;
  final String currentTime;
  final bool isDoctor;
  final Function(DateTime newDate, String newTime, String? reason) onConfirm;

  const RescheduleDialog({
    Key? key,
    required this.appointmentId,
    required this.currentDate,
    required this.currentTime,
    required this.isDoctor,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentDate;
    // Parse the current time
    final timeParts = widget.currentTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 9,
      minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    setState(() {
      _isSubmitting = true;
    });

    final newTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final reason =
        _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim();

    widget.onConfirm(_selectedDate, newTime, reason);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'fr_FR');

    return AlertDialog(
      title: Text(
        widget.isDoctor 
            ? context.tr('reschedule.reschedule_appointment') 
            : context.tr('reschedule.request_reschedule'),
        style: GoogleFonts.raleway(
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDoctor
                  ? context.tr('reschedule.select_new_date_time')
                  : context.tr('reschedule.request_new_date_time'),
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),

            // Date picker
            Text(
              context.tr('referrals.appointment_date'),
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        dateFormatter.format(_selectedDate),
                        style: GoogleFonts.raleway(fontSize: 14.sp),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Time picker
            Text(
              context.tr('referrals.appointment_time'),
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: _selectTime,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _selectedTime.format(context),
                        style: GoogleFonts.raleway(fontSize: 14.sp),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Reason (optional)
            Text(
              context.tr('reschedule.reason_optional'),
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr('reschedule.enter_reason'),
                hintStyle: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.tr('common.cancel'),
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isSubmitting
                  ? SizedBox(
                    height: 20.sp,
                    width: 20.sp,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    widget.isDoctor 
                        ? context.tr('reschedule.reschedule') 
                        : context.tr('reschedule.send_request'),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Dialog shown to doctor when patient has requested a reschedule
class RescheduleRequestDialog extends StatelessWidget {
  final String appointmentId;
  final DateTime requestedDate;
  final String requestedTime;
  final String? reason;
  final VoidCallback onApprove;
  final Function(String? rejectReason) onReject;

  const RescheduleRequestDialog({
    Key? key,
    required this.appointmentId,
    required this.requestedDate,
    required this.requestedTime,
    this.reason,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'fr_FR');

    return AlertDialog(
      title: Text(
        context.tr('reschedule.reschedule_request'),
        style: GoogleFonts.raleway(
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('reschedule.patient_requested_reschedule'),
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),

          // Requested date
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: context.tr('reschedule.requested_date'),
            value: dateFormatter.format(requestedDate),
          ),
          SizedBox(height: 12.h),

          // Requested time
          _buildInfoRow(
            icon: Icons.access_time,
            label: context.tr('reschedule.requested_time'),
            value: requestedTime,
          ),

          if (reason != null && reason!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.comment,
              label: context.tr('reschedule.reason'),
              value: reason!,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showRejectDialog(context);
          },
          child: Text(
            context.tr('reschedule.reject'),
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onApprove();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            context.tr('reschedule.approve'),
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              context.tr('reschedule.reject_reschedule'),
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('reschedule.provide_rejection_reason'),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.tr('reschedule.enter_reason'),
                    hintStyle: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey[400],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  context.tr('common.cancel'),
                  style: GoogleFonts.raleway(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onReject(
                    reasonController.text.isEmpty
                        ? null
                        : reasonController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  context.tr('reschedule.reject'),
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
