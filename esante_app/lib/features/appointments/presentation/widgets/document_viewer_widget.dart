import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/document_entity.dart';
import '../screens/document_preview_screen.dart';

/// Widget for viewing documents attached to an appointment
class DocumentViewerWidget extends StatelessWidget {
  final List<AppointmentDocumentEntity> documents;
  final bool showTitle;
  final VoidCallback? onAddDocument;
  final Function(String documentId)? onRemoveDocument;
  final bool canModify;

  const DocumentViewerWidget({
    super.key,
    required this.documents,
    this.showTitle = true,
    this.onAddDocument,
    this.onRemoveDocument,
    this.canModify = false,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty && !canModify) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 18.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${documents.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (canModify && onAddDocument != null)
                IconButton(
                  onPressed: onAddDocument,
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 22.sp,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Add Document',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        if (documents.isEmpty)
          _buildEmptyState(context)
        else
          ...documents.map((doc) => _buildDocumentItem(context, doc)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 20.sp,
            color: Colors.grey,
          ),
          SizedBox(width: 8.w),
          Text(
            'No documents attached',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, AppointmentDocumentEntity doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Document type icon
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: _getDocumentColor(doc.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                doc.type.icon,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getDocumentColor(doc.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        doc.type.displayName,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: _getDocumentColor(doc.type),
                        ),
                      ),
                    ),
                    if (doc.uploadedAt != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        _formatDate(doc.uploadedAt!),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (doc.description != null && doc.description!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    doc.description!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View/Download button
              IconButton(
                onPressed: () => _openDocument(context, doc),
                icon: Icon(
                  doc.isImage ? Icons.visibility_outlined : Icons.download_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                tooltip: doc.isImage ? 'View' : 'Download',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.all(8.w),
              ),
              // Delete button (if modifiable)
              if (canModify && onRemoveDocument != null && doc.id != null)
                IconButton(
                  onPressed: () => _confirmDelete(context, doc),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20.sp,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(8.w),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.labResult:
        return Colors.blue;
      case DocumentType.imaging:
        return Colors.purple;
      case DocumentType.prescription:
        return Colors.green;
      case DocumentType.referralLetter:
        return Colors.orange;
      case DocumentType.medicalRecord:
        return Colors.teal;
      case DocumentType.other:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openDocument(BuildContext context, AppointmentDocumentEntity doc) async {
    // Navigate to full-screen document preview
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(document: doc),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppointmentDocumentEntity doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Document'),
        content: Text('Are you sure you want to remove "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveDocument?.call(doc.id!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Compact document badge for showing in appointment cards
class DocumentBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const DocumentBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              size: 14.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
