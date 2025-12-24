import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page for doctors to view a patient's shared medical documents
class PatientDocumentsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDocumentsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDocumentsPage> createState() => _PatientDocumentsPageState();
}

class _PatientDocumentsPageState extends State<PatientDocumentsPage> {
  String? _selectedType;

  List<Map<String, dynamic>> _getDocumentTypes(BuildContext context) {
    return [
      {'value': null, 'label': context.tr('common.all'), 'icon': Icons.folder},
      {'value': 'lab_result', 'label': context.tr('medical_records.lab_result'), 'icon': Icons.science},
      {'value': 'imaging', 'label': context.tr('medical_records.imaging'), 'icon': Icons.image},
      {'value': 'prescription', 'label': context.tr('medical_records.prescription'), 'icon': Icons.medication},
      {'value': 'insurance', 'label': context.tr('medical_records.insurance'), 'icon': Icons.verified_user},
      {'value': 'medical_report', 'label': context.tr('medical_records.medical_report'), 'icon': Icons.description},
      {'value': 'other', 'label': context.tr('medical_records.other'), 'icon': Icons.attach_file},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MedicalRecordsBloc>()
        ..add(GetPatientDocumentsEvent(
          patientId: widget.patientId,
          documentType: _selectedType,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('medical_records.patient_documents'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.patientName,
                style: GoogleFonts.raleway(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryColor,
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              tooltip: context.tr('medical_records.filter_by_type'),
              onSelected: (value) {
                setState(() => _selectedType = value);
                _loadDocuments(context);
              },
              itemBuilder: (context) => _getDocumentTypes(context)
                  .map((type) => PopupMenuItem<String?>(
                        value: type['value'],
                        child: Row(
                          children: [
                            Icon(type['icon'], size: 20.sp, color: AppColors.primaryColor),
                            SizedBox(width: 12.w),
                            Text(type['label']),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter indicator
            if (_selectedType != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: AppColors.primaryColor.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _getTypeLabel(context, _selectedType!),
                      style: GoogleFonts.raleway(
                        fontSize: 12.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedType = null);
                        _loadDocuments(context);
                      },
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            // Documents list
            Expanded(
              child: BlocBuilder<MedicalRecordsBloc, MedicalRecordsState>(
                builder: (context, state) {
                  if (state is DocumentLoading) {
                    return LoadingStateWidget(
                      message: context.tr('medical_records.loading_documents'),
                    );
                  }

                  if (state is DocumentError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => _loadDocuments(context),
                      retryText: context.tr('medical_records.retry'),
                    );
                  }

                  if (state is PatientDocumentsLoaded) {
                    if (state.documents.isEmpty) {
                      return EmptyStateWidget(
                        message: context.tr('medical_records.no_shared_documents'),
                        description: context.tr('medical_records.no_shared_documents_desc'),
                      );
                    }
                    return _buildDocumentsList(context, state.documents);
                  }

                  return LoadingStateWidget(
                    message: context.tr('medical_records.loading_documents'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadDocuments(BuildContext context) {
    context.read<MedicalRecordsBloc>().add(
          GetPatientDocumentsEvent(
            patientId: widget.patientId,
            documentType: _selectedType,
          ),
        );
  }

  String _getTypeLabel(BuildContext context, String type) {
    final typeMap = _getDocumentTypes(context).firstWhere(
      (t) => t['value'] == type,
      orElse: () => {'label': type},
    );
    return typeMap['label'];
  }

  Widget _buildDocumentsList(
    BuildContext context,
    List<MedicalDocumentEntity> documents,
  ) {
    // Group documents by type
    final groupedDocuments = <String, List<MedicalDocumentEntity>>{};
    for (final doc in documents) {
      groupedDocuments.putIfAbsent(doc.documentType, () => []).add(doc);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDocuments(context),
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: groupedDocuments.length,
        itemBuilder: (context, index) {
          final type = groupedDocuments.keys.elementAt(index);
          final docs = groupedDocuments[type]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: 20.sp,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _getTypeLabel(context, type),
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${docs.length}',
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Documents
              ...docs.map((doc) => _buildDocumentCard(context, doc)),

              SizedBox(height: 16.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, MedicalDocumentEntity document) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _viewDocument(document),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Document icon
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getTypeColor(document.documentType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getDocumentIcon(document.mimeType),
                  size: 24.sp,
                  color: _getTypeColor(document.documentType),
                ),
              ),

              SizedBox(width: 12.w),

              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          document.documentDate != null
                              ? DateFormat('dd/MM/yyyy').format(document.documentDate!)
                              : context.tr('medical_records.no_date'),
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.storage,
                          size: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatFileSize(document.fileSize),
                          style: GoogleFonts.raleway(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (document.description != null &&
                        document.description!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        document.description!,
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: Icon(
                  Icons.download,
                  color: AppColors.primaryColor,
                  size: 24.sp,
                ),
                onPressed: () => _downloadDocument(context, document),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'lab_result':
        return Icons.science;
      case 'imaging':
        return Icons.image;
      case 'prescription':
        return Icons.medication;
      case 'insurance':
        return Icons.verified_user;
      case 'medical_report':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  IconData _getDocumentIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.article;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'lab_result':
        return Colors.purple;
      case 'imaging':
        return Colors.blue;
      case 'prescription':
        return Colors.green;
      case 'insurance':
        return Colors.orange;
      case 'medical_report':
        return AppColors.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _viewDocument(MedicalDocumentEntity document) async {
    if (document.s3Url != null) {
      final uri = Uri.parse(document.s3Url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          context.tr('medical_records.error'),
          context.tr('medical_records.cannot_open_document'),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _downloadDocument(BuildContext context, MedicalDocumentEntity document) {
    context.read<MedicalRecordsBloc>().add(
          DownloadDocumentEvent(documentId: document.id!),
        );
    Get.snackbar(
      context.tr('medical_records.downloading'),
      document.title,
      backgroundColor: AppColors.primaryColor,
      colorText: Colors.white,
    );
  }
}
