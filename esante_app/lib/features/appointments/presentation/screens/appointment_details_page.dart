import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../widgets/appointment_info_cards.dart';
import '../widgets/document_attachment_widget.dart';
import '../widgets/document_viewer_widget.dart';
import '../../../doctors/presentation/screens/doctor_detail_screen.dart';
import 'appointment_actions.dart';

/// Full-screen appointment details page for both patient and doctor views
class AppointmentDetailsPage extends StatefulWidget {
  final AppointmentEntity appointment;
  final bool isPatientView;
  final VoidCallback? onAppointmentChanged;

  const AppointmentDetailsPage({
    super.key,
    required this.appointment,
    required this.isPatientView,
    this.onAppointmentChanged,
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  List<AppointmentDocumentEntity> _documents = [];
  bool _isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final repository = sl<AppointmentRepository>();
      final result = await repository.getAppointmentDocuments(
        appointmentId: widget.appointment.id,
      );
      result.fold(
        (failure) => setState(() => _isLoadingDocuments = false),
        (documents) => setState(() {
          _documents = documents;
          _isLoadingDocuments = false;
        }),
      );
    } catch (e) {
      setState(() => _isLoadingDocuments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Appointment Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              AppointmentStatusBanner(appointment: appointment),
              SizedBox(height: 20.h),

              // Person Info Card
              PersonInfoCard(
                appointment: appointment,
                isPatientView: widget.isPatientView,
                onTap: widget.isPatientView 
                    ? () => _viewDoctorProfile(appointment.doctorId)
                    : null,
              ),
              SizedBox(height: 16.h),

              // Date & Time Card
              DateTimeCard(appointment: appointment),
              SizedBox(height: 16.h),

              // Reason Card
              if (appointment.reason != null && appointment.reason!.isNotEmpty)
                ReasonCard(reason: appointment.reason!),

              // Referral Info
              if (appointment.isReferral) ...[
                SizedBox(height: 16.h),
                ReferralInfoCard(appointment: appointment),
              ],

              // Reschedule Info
              if (appointment.isRescheduled) ...[
                SizedBox(height: 16.h),
                RescheduleInfoCard(appointment: appointment),
              ],

              // Cancellation Info
              if (appointment.status == AppointmentStatus.cancelled) ...[
                SizedBox(height: 16.h),
                CancellationCard(appointment: appointment),
              ],

              // Rejection Info
              if (appointment.status == AppointmentStatus.rejected) ...[
                SizedBox(height: 16.h),
                RejectionCard(appointment: appointment),
              ],

              // Notes
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                NotesCard(notes: appointment.notes!),
              ],

              // Documents Section
              SizedBox(height: 24.h),
              _buildDocumentsSection(),

              // Actions Section
              SizedBox(height: 24.h),
              if (widget.isPatientView)
                PatientAppointmentActions(
                  appointment: appointment,
                  onAppointmentChanged: widget.onAppointmentChanged,
                )
              else
                DoctorAppointmentActions(
                  appointment: appointment,
                  onAppointmentChanged: widget.onAppointmentChanged,
                ),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
      // FAB for adding documents (patient only, active appointments)
      floatingActionButton: widget.isPatientView && appointment.status.isActive
          ? FloatingActionButton.extended(
              onPressed: _addDocuments,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Document'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_outlined, color: AppColors.primary, size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Documents',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8.w),
            if (_documents.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${_documents.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_isLoadingDocuments)
          const Center(child: CircularProgressIndicator())
        else if (_documents.isEmpty)
          _buildEmptyDocuments()
        else
          DocumentViewerWidget(
            documents: _documents,
            canModify: widget.isPatientView,
            onRemoveDocument: widget.isPatientView ? _removeDocument : null,
          ),
      ],
    );
  }

  Widget _buildEmptyDocuments() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.folder_open,
                size: 48.sp,
                color: AppColors.grey400,
              ),
              SizedBox(height: 12.h),
              Text(
                'No documents attached',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey500,
                ),
              ),
              if (widget.isPatientView && widget.appointment.status.isActive) ...[
                SizedBox(height: 16.h),
                OutlinedButton.icon(
                  onPressed: _addDocuments,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Document'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeDocument(String documentId) async {
    try {
      final repository = sl<AppointmentRepository>();
      final result = await repository.removeDocumentFromAppointment(
        appointmentId: widget.appointment.id,
        documentId: documentId,
      );
      result.fold(
        (failure) => AppSnackBar.error(context, failure.message),
        (_) {
          setState(() {
            _documents.removeWhere((d) => d.id == documentId);
          });
          AppSnackBar.success(context, 'Document removed');
          widget.onAppointmentChanged?.call();
        },
      );
    } catch (e) {
      AppSnackBar.error(context, 'Failed to remove document');
    }
  }

  Future<void> _addDocuments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDocumentSheet(
        appointmentId: widget.appointment.id,
        onDocumentsAdded: () {
          Navigator.pop(context);
          _loadDocuments();
          widget.onAppointmentChanged?.call();
        },
      ),
    );
  }

  void _viewDoctorProfile(String doctorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailScreen(doctorId: doctorId),
      ),
    );
  }
}

/// Bottom sheet for adding documents
class _AddDocumentSheet extends StatefulWidget {
  final String appointmentId;
  final VoidCallback onDocumentsAdded;

  const _AddDocumentSheet({
    required this.appointmentId,
    required this.onDocumentsAdded,
  });

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  final List<PendingDocumentAttachment> _attachments = [];
  bool _isUploading = false;

  Future<void> _uploadDocuments() async {
    if (_attachments.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final repository = sl<AppointmentRepository>();
      int successCount = 0;

      for (final attachment in _attachments) {
        // First upload the file to get URL
        final uploadResult = await repository.uploadDocumentFile(
          filePath: attachment.localPath,
          fileName: attachment.fileName,
          appointmentId: widget.appointmentId,
        );

        await uploadResult.fold(
          (failure) async {},
          (url) async {
            // Then add document to appointment
            final result = await repository.addDocumentToAppointment(
              appointmentId: widget.appointmentId,
              name: attachment.fileName,
              url: url,
              type: attachment.type,
              description: attachment.description,
            );
            result.fold(
              (failure) {},
              (_) => successCount++,
            );
          },
        );
      }

      if (successCount > 0) {
        if (mounted) {
          AppSnackBar.success(context, '$successCount document(s) uploaded');
        }
        widget.onDocumentsAdded();
      } else {
        if (mounted) {
          AppSnackBar.error(context, 'Failed to upload documents');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error uploading documents');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Documents',
                    style: TextStyle(
                      fontSize: 20.sp,
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
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: DocumentAttachmentWidget(
                  attachments: _attachments,
                  onAttachmentsChanged: (attachments) {
                    setState(() {
                      _attachments.clear();
                      _attachments.addAll(attachments);
                    });
                  },
                  maxFiles: 5,
                ),
              ),
            ),
            if (_attachments.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16.r),
                child: CustomButton(
                  text: _isUploading 
                      ? 'Uploading...' 
                      : 'Upload ${_attachments.length} Document(s)',
                  onPressed: _isUploading ? null : _uploadDocuments,
                  isLoading: _isUploading,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
