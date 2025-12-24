import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medical_app/core/l10n/translator.dart';
import '../../domain/entities/medical_file_entity.dart';

class MedicalFileItem extends StatelessWidget {
  final MedicalFileEntity file;
  final VoidCallback onDelete;
  final Function(String?) onUpdateDescription;

  const MedicalFileItem({
    Key? key,
    required this.file,
    required this.onDelete,
    required this.onUpdateDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFileTypeIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${file.fileType} · ${file.fileSize}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('medical_records.added_on')} ${_formatDate(file.createdAt)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildPopupMenu(context),
              ],
            ),
            if (file.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('medical_records.description')}:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewFile(context),
                  icon: const Icon(Icons.visibility, size: 20),
                  label: Text(context.tr('common.view')),
                ),
                TextButton.icon(
                  onPressed: () => onUpdateDescription(file.description),
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text(context.tr('common.modify')),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  label: Text(
                    context.tr('common.delete'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData iconData;
    Color iconColor;

    if (file.isImage) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (file.isPdf) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.amber;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'view', child: Text(context.tr('common.consult'))),
            PopupMenuItem(
              value: 'edit',
              child: Text(context.tr('common.modify_description')),
            ),
            PopupMenuItem(value: 'delete', child: Text(context.tr('common.delete'))),
          ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewFile(context);
            break;
          case 'edit':
            onUpdateDescription(file.description);
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      icon: const Icon(Icons.more_vert),
    );
  }

  void _viewFile(BuildContext context) async {
    try {
      final url = Uri.parse(file.path);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('medical_records.cannot_open_file')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('common.error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
