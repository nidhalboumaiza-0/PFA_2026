import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/util/snackbar_message.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:path/path.dart' as path;
import '../../../../core/widgets/loading_widget.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../domain/entities/dossier_medical_entity.dart';
import '../../domain/entities/medical_file_entity.dart';
import '../bloc/dossier_medical_bloc.dart';
import '../bloc/dossier_medical_event.dart';
import '../bloc/dossier_medical_state.dart';
import '../widgets/medical_file_item.dart';

class DossierMedicalScreen extends StatefulWidget {
  final String patientId;

  const DossierMedicalScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<DossierMedicalScreen> createState() => _DossierMedicalScreenState();
}

class _DossierMedicalScreenState extends State<DossierMedicalScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Don't call _loadDossierMedical() here anymore
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDossierMedical();
  }

  void _loadDossierMedical() {
    try {
      final bloc = BlocProvider.of<DossierMedicalBloc>(context);
      bloc.add(FetchDossierMedical(patientId: widget.patientId));
    } catch (e) {
      print('Error getting DossierMedicalBloc: $e');
      // Show a snackbar with the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('medical_records.error_loading_records')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        final description = await _showDescriptionDialog();
        if (description != null) {
          BlocProvider.of<DossierMedicalBloc>(context).add(
            UploadSingleFile(
              patientId: widget.patientId,
              filePath: file.path!,
              description: description,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = <String>[];
      final descriptions = <String, String>{};

      for (final file in result.files) {
        if (file.path != null) {
          paths.add(file.path!);
          // Use the filename as the key for the description
          descriptions[path.basename(file.path!)] = '';
        }
      }

      if (paths.isNotEmpty) {
        BlocProvider.of<DossierMedicalBloc>(context).add(
          UploadMultipleFiles(
            patientId: widget.patientId,
            filePaths: paths,
            descriptions: descriptions,
          ),
        );
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('document_description')),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: context.tr('enter_description_optional'),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(context.tr('confirm')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('medical_records'))),
      body: BlocConsumer<DossierMedicalBloc, DossierMedicalState>(
        listener: (context, state) {
          if (state is FileUploadSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: context.tr('documents_added_successfully'),
              context: context,
            );
          } else if (state is FileUploadError) {
            SnackBarMessage().showErrorSnackBar(
              message: context.tr('error') + ': ${state.message}',
              context: context,
            );
          } else if (state is FileDeleteSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: context.tr('document_deleted_successfully'),
              context: context,
            );
          } else if (state is FileDeleteError) {
            SnackBarMessage().showErrorSnackBar(
              message: context.tr('error') + ': ${state.message}',
              context: context,
            );
          } else if (state is FileDescriptionUpdateSuccess) {
            SnackBarMessage().showSuccessSnackBar(
              message: context.tr('description_updated_successfully'),
              context: context,
            );
          } else if (state is FileDescriptionUpdateError) {
            SnackBarMessage().showErrorSnackBar(
              message: context.tr('error') + ': ${state.message}',
              context: context,
            );
          }
        },
        builder: (context, state) {
          if (state is DossierMedicalLoading || state is FileUploadLoading) {
            return const LoadingWidget();
          } else if (state is DossierMedicalLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: _buildDossierContent(state.dossier),
            );
          } else if (state is DossierMedicalEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: _buildEmptyDossier(),
            );
          } else if (state is DossierMedicalError) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDossierMedical();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Text(
                        context.tr('error') + ': ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _loadDossierMedical();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadDossierMedical,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.tr('load_medical_records')),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _pickAndUploadFile,
            heroTag: 'addSingleFile',
            tooltip: context.tr('add_document'),
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _pickAndUploadMultipleFiles,
            heroTag: 'addMultipleFiles',
            tooltip: context.tr('add_multiple_documents'),
            child: const Icon(Icons.add_photo_alternate),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierContent(DossierMedicalEntity dossier) {
    if (dossier.files.isEmpty) {
      return _buildEmptyDossier();
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: dossier.files.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final file = dossier.files[index];
        return MedicalFileItem(
          file: file,
          onDelete: () => _confirmDeleteFile(file),
          onUpdateDescription:
              (description) => _updateFileDescription(file, description),
        );
      },
    );
  }

  Widget _buildEmptyDossier() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: EmptyStateWidget(
            message: context.tr('no_documents_in_medical_records'),
            actionText: context.tr('add_document'),
            onAction: _pickAndUploadFile,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteFile(MedicalFileEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('delete_document')),
            content: Text(
              context.tr('confirm_delete_document', args: {'name': file.displayName}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(context.tr('delete')),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      context.read<DossierMedicalBloc>().add(
        DeleteFile(patientId: widget.patientId, fileId: file.id),
      );
    }
  }

  Future<void> _updateFileDescription(
    MedicalFileEntity file,
    String? initialDescription,
  ) async {
    final controller = TextEditingController(
      text: initialDescription ?? file.description,
    );

    final newDescription = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('edit_description')),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: context.tr('enter_description')),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(context.tr('save')),
              ),
            ],
          ),
    );

    if (newDescription != null && newDescription != file.description) {
      context.read<DossierMedicalBloc>().add(
        UpdateFileDescription(
          patientId: widget.patientId,
          fileId: file.id,
          description: newDescription,
        ),
      );
    }
  }
}
