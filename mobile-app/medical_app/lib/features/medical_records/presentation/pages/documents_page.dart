import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class DocumentsPage extends StatefulWidget {
  final bool isPatientView;

  const DocumentsPage({
    super.key,
    this.isPatientView = true,
  });

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String? _selectedType;

  List<Map<String, dynamic>> _getDocumentTypes(BuildContext context) => [
    {'value': null, 'label': context.tr('medical_records.all')},
    {'value': 'lab_result', 'label': context.tr('medical_records.lab_result')},
    {'value': 'imaging', 'label': context.tr('medical_records.imaging')},
    {'value': 'prescription', 'label': context.tr('medical_records.prescription')},
    {'value': 'insurance', 'label': context.tr('medical_records.insurance')},
    {'value': 'medical_report', 'label': context.tr('medical_records.medical_report')},
    {'value': 'other', 'label': context.tr('medical_records.other')},
  ];

  @override
  Widget build(BuildContext context) {
    final documentTypes = _getDocumentTypes(context);
    return BlocProvider(
      create: (_) => sl<MedicalRecordsBloc>()..add(const GetMyDocumentsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medical_records.my_documents')),
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('medical_records.filter_by_type'),
              onSelected: (value) {
                setState(() => _selectedType = value);
                _loadDocuments();
              },
              itemBuilder: (context) => documentTypes
                  .map((type) => PopupMenuItem<String?>(
                        value: type['value'],
                        child: Text(type['label']),
                      ))
                  .toList(),
            ),
          ],
        ),
        body: BlocConsumer<MedicalRecordsBloc, MedicalRecordsState>(
          listener: (context, state) {
            if (state is DocumentUploaded) {
              Get.snackbar(
                context.tr('medical_records.success'),
                context.tr('medical_records.document_uploaded'),
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              // Reload documents
              context
                  .read<MedicalRecordsBloc>()
                  .add(GetMyDocumentsEvent(documentType: _selectedType));
            } else if (state is DocumentDeleted) {
              Get.snackbar(
                context.tr('medical_records.success'),
                context.tr('medical_records.document_deleted'),
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              // Reload documents
              context
                  .read<MedicalRecordsBloc>()
                  .add(GetMyDocumentsEvent(documentType: _selectedType));
            } else if (state is DocumentError) {
              Get.snackbar(
                context.tr('medical_records.error'),
                state.message,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          },
          builder: (context, state) {
            if (state is DocumentLoading ||
                state is DocumentUploading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    if (state is DocumentUploading) ...[
                      const SizedBox(height: 16),
                      Text(context.tr('medical_records.uploading')),
                    ],
                  ],
                ),
              );
            }

            if (state is DocumentError) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is MyDocumentsLoaded) {
              if (state.documents.isEmpty) {
                return _buildEmptyWidget(context);
              }
              return _buildDocumentsList(context, state.documents);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showUploadOptions(context),
          icon: const Icon(Icons.upload_file),
          label: Text(context.tr('medical_records.upload')),
          backgroundColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  void _loadDocuments() {
    context.read<MedicalRecordsBloc>().add(
          GetMyDocumentsEvent(documentType: _selectedType),
        );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.tr('medical_records.take_photo')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('medical_records.choose_from_gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(context.tr('medical_records.pick_document')),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      _showUploadDialog(File(image.path));
    }
  }

  void _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      _showUploadDialog(File(result.files.single.path!));
    }
  }

  void _showUploadDialog(File file) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'other';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('medical_records.upload_document')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                file.path.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.description'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.document_type'),
                  border: const OutlineInputBorder(),
                ),
                items: _getDocumentTypes(context)
                    .where((t) => t['value'] != null)
                    .map((type) => DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedType = value ?? 'other';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('medical_records.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                Get.snackbar(
                  context.tr('medical_records.error'),
                  context.tr('medical_records.title_required'),
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<MedicalRecordsBloc>().add(
                    UploadDocumentEvent(
                      file: file,
                      documentType: selectedType,
                      title: titleController.text,
                      description: descriptionController.text.isNotEmpty
                          ? descriptionController.text
                          : null,
                    ),
                  );
            },
            child: Text(context.tr('medical_records.upload')),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: _loadDocuments,
      retryText: context.tr('medical_records.retry'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return EmptyStateWidget(
      message: context.tr('medical_records.no_documents'),
      description: context.tr('medical_records.no_documents_desc'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildDocumentsList(
      BuildContext context, List<MedicalDocumentEntity> documents) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadDocuments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          return _DocumentCard(
            document: document,
            onTap: () => _openDocument(document),
            onDelete: () => _confirmDeleteDocument(context, document),
            onShare: () => _showShareDialog(context, document),
          );
        },
      ),
    );
  }

  void _openDocument(MedicalDocumentEntity document) {
    if (document.id == null) return;
    context.read<MedicalRecordsBloc>().add(
          DownloadDocumentEvent(documentId: document.id!),
        );
  }

  void _confirmDeleteDocument(
      BuildContext context, MedicalDocumentEntity document) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('medical_records.delete_document')),
        content: Text(context.tr('medical_records.delete_document_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('medical_records.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (document.id != null) {
                context.read<MedicalRecordsBloc>().add(
                      DeleteDocumentEvent(documentId: document.id!),
                    );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('medical_records.delete')),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, MedicalDocumentEntity document) {
    bool shareWithAll = document.isSharedWithAllDoctors;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.tr('medical_records.share_document')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(context.tr('medical_records.share_with_all_doctors')),
                value: shareWithAll,
                onChanged: (value) {
                  setState(() => shareWithAll = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('medical_records.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (document.id != null) {
                  context.read<MedicalRecordsBloc>().add(
                        UpdateDocumentSharingEvent(
                          documentId: document.id!,
                          isSharedWithAllDoctors: shareWithAll,
                        ),
                      );
                }
              },
              child: Text(context.tr('medical_records.save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MedicalDocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDocumentTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentTypeIcon(),
                  color: _getDocumentTypeColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.documentTypeDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.uploadDate != null 
                            ? DateFormat('dd/MM/yyyy').format(document.uploadDate!)
                            : '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (document.isSharedWithAllDoctors) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.public,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            context.tr('medical_records.shared'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      onShare();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('medical_records.share')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('medical_records.delete'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
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

  IconData _getDocumentTypeIcon() {
    switch (document.documentType) {
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
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentTypeColor() {
    switch (document.documentType) {
      case 'lab_result':
        return Colors.purple;
      case 'imaging':
        return Colors.blue;
      case 'prescription':
        return Colors.green;
      case 'insurance':
        return Colors.orange;
      case 'medical_report':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
