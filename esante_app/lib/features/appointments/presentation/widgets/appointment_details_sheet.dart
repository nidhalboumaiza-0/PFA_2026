import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../widgets/document_viewer_widget.dart';
import '../widgets/document_attachment_widget.dart';

/// Bottom sheet for viewing appointment details including documents
class AppointmentDetailsSheet extends StatefulWidget {
  final AppointmentEntity appointment;
  final bool isPatientView;
  final VoidCallback? onDocumentsChanged;

  const AppointmentDetailsSheet({
    super.key,
    required this.appointment,
    this.isPatientView = true,
    this.onDocumentsChanged,
  });

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    required AppointmentEntity appointment,
    bool isPatientView = true,
    VoidCallback? onDocumentsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentDetailsSheet(
        appointment: appointment,
        isPatientView: isPatientView,
        onDocumentsChanged: onDocumentsChanged,
      ),
    );
  }

  @override
  State<AppointmentDetailsSheet> createState() => _AppointmentDetailsSheetState();
}

class _AppointmentDetailsSheetState extends State<AppointmentDetailsSheet> {
  final AppointmentRepository _repository = sl<AppointmentRepository>();
  List<AppointmentDocumentEntity> _documents = [];
  bool _isLoadingDocuments = true;
  String? _documentsError;
  bool _isAddingDocument = false;
  List<PendingDocumentAttachment> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
      _documentsError = null;
    });

    final result = await _repository.getAppointmentDocuments(
      appointmentId: widget.appointment.id,
    );

    result.fold(
      (failure) {
        setState(() {
          _documentsError = failure.message;
          _isLoadingDocuments = false;
        });
      },
      (documents) {
        setState(() {
          _documents = documents;
          _isLoadingDocuments = false;
        });
      },
    );
  }

  Future<void> _removeDocument(String documentId) async {
    final result = await _repository.removeDocumentFromAppointment(
      appointmentId: widget.appointment.id,
      documentId: documentId,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove document: ${failure.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        setState(() {
          _documents.removeWhere((d) => d.id == documentId);
        });
        widget.onDocumentsChanged?.call();
      },
    );
  }

  Future<void> _uploadPendingDocuments() async {
    if (_pendingAttachments.isEmpty) return;

    for (final attachment in _pendingAttachments) {
      final result = await _repository.addDocumentToAppointment(
        appointmentId: widget.appointment.id,
        name: attachment.fileName,
        url: 'file://${attachment.localPath}',
        type: attachment.type,
        description: attachment.description,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload ${attachment.fileName}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (document) {
          setState(() {
            _documents.add(document);
          });
        },
      );
    }

    setState(() {
      _pendingAttachments = [];
      _isAddingDocument = false;
    });
    widget.onDocumentsChanged?.call();
  }

  bool get _canModifyDocuments {
    // Only allow modifications for pending or confirmed appointments
    return widget.isPatientView &&
        (widget.appointment.status == AppointmentStatus.pending ||
            widget.appointment.status == AppointmentStatus.confirmed);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppointmentInfo(),
                      SizedBox(height: 24.h),
                      _buildDocumentsSection(),
                      if (_isAddingDocument) ...[
                        SizedBox(height: 16.h),
                        _buildAddDocumentSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppointmentInfo() {
    final apt = widget.appointment;
    return Container(
      padding: EdgeInsets.all(16.w),
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
          // Person info
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  widget.isPatientView ? Icons.medical_services : Icons.person,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isPatientView
                          ? apt.doctorInfo?.fullName ?? 'Doctor'
                          : apt.patientInfo?.fullName ?? 'Patient',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.isPatientView && apt.doctorInfo?.specialty != null)
                      Text(
                        apt.doctorInfo!.specialty,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(apt.status),
            ],
          ),
          SizedBox(height: 16.h),
          // Date and Time
          Row(
            children: [
              _buildInfoItem(
                Icons.calendar_today_outlined,
                'Date',
                _formatDate(apt.appointmentDate),
              ),
              SizedBox(width: 24.w),
              _buildInfoItem(
                Icons.access_time,
                'Time',
                apt.appointmentTime,
              ),
            ],
          ),
          if (apt.reason != null && apt.reason!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoItem(
              Icons.notes_outlined,
              'Reason',
              apt.reason!,
              isMultiline: true,
            ),
          ],
          if (apt.notes != null && apt.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoItem(
              Icons.edit_note,
              'Notes',
              apt.notes!,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isMultiline = false}) {
    return isMultiline
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: 22.w),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.only(left: 22.w),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    switch (status) {
      case AppointmentStatus.confirmed:
        color = Colors.green;
        break;
      case AppointmentStatus.pending:
        color = Colors.orange;
        break;
      case AppointmentStatus.completed:
        color = Colors.blue;
        break;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rejected:
        color = Colors.red;
        break;
      case AppointmentStatus.noShow:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_canModifyDocuments && !_isAddingDocument)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingDocument = true;
                  });
                },
                icon: Icon(Icons.add, size: 18.sp),
                label: const Text('Add'),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_isLoadingDocuments)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: CircularProgressIndicator(strokeWidth: 2.w),
            ),
          )
        else if (_documentsError != null)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _documentsError!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadDocuments,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          DocumentViewerWidget(
            documents: _documents,
            showTitle: false,
            canModify: _canModifyDocuments,
            onRemoveDocument: _removeDocument,
          ),
      ],
    );
  }

  Widget _buildAddDocumentSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Documents',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isAddingDocument = false;
                    _pendingAttachments = [];
                  });
                },
                icon: const Icon(Icons.close),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          DocumentAttachmentWidget(
            attachments: _pendingAttachments,
            onAttachmentsChanged: (attachments) {
              setState(() {
                _pendingAttachments = attachments;
              });
            },
            maxFiles: 5 - _documents.length,
          ),
          if (_pendingAttachments.isNotEmpty) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadPendingDocuments,
                icon: const Icon(Icons.upload),
                label: Text('Upload ${_pendingAttachments.length} Document(s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
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
