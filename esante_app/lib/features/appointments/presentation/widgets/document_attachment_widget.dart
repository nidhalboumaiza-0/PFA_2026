import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/document_entity.dart';

/// Widget for selecting and managing document attachments for appointments
class DocumentAttachmentWidget extends StatefulWidget {
  final List<PendingDocumentAttachment> attachments;
  final Function(List<PendingDocumentAttachment>) onAttachmentsChanged;
  final int maxFiles;
  final int maxFileSizeMB;

  const DocumentAttachmentWidget({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.maxFiles = 5,
    this.maxFileSizeMB = 10,
  });

  @override
  State<DocumentAttachmentWidget> createState() => _DocumentAttachmentWidgetState();
}

class _DocumentAttachmentWidgetState extends State<DocumentAttachmentWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickFile() async {
    if (widget.attachments.length >= widget.maxFiles) {
      _showError('Maximum ${widget.maxFiles} files allowed');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (file.path == null) {
        _showError('Could not access the file');
        return;
      }
      
      // Check file size
      final fileSizeBytes = file.size;
      final maxSizeBytes = widget.maxFileSizeMB * 1024 * 1024;
      
      if (fileSizeBytes > maxSizeBytes) {
        _showError('File size must be less than ${widget.maxFileSizeMB}MB');
        return;
      }

      final attachment = PendingDocumentAttachment(
        localPath: file.path!,
        fileName: file.name,
        type: _getDocumentType(file.name),
        fileSize: fileSizeBytes,
      );

      final newList = [...widget.attachments, attachment];
      widget.onAttachmentsChanged(newList);
    }
  }

  Future<void> _takePhoto() async {
    if (widget.attachments.length >= widget.maxFiles) {
      _showError('Maximum ${widget.maxFiles} files allowed');
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();
      
      final attachment = PendingDocumentAttachment(
        localPath: image.path,
        fileName: image.name,
        type: DocumentType.other,
        fileSize: fileSize,
      );

      final newList = [...widget.attachments, attachment];
      widget.onAttachmentsChanged(newList);
    }
  }

  void _removeAttachment(int index) {
    final newList = List<PendingDocumentAttachment>.from(widget.attachments);
    newList.removeAt(index);
    widget.onAttachmentsChanged(newList);
  }

  void _updateDocumentType(int index, DocumentType type) {
    final newList = List<PendingDocumentAttachment>.from(widget.attachments);
    final oldAttachment = newList[index];
    newList[index] = PendingDocumentAttachment(
      localPath: oldAttachment.localPath,
      fileName: oldAttachment.fileName,
      type: type,
      description: oldAttachment.description,
      fileSize: oldAttachment.fileSize,
    );
    widget.onAttachmentsChanged(newList);
  }

  DocumentType _getDocumentType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.contains('lab') || lowerName.contains('test')) {
      return DocumentType.labResult;
    } else if (lowerName.contains('xray') || lowerName.contains('scan') || lowerName.contains('mri')) {
      return DocumentType.imaging;
    } else if (lowerName.contains('prescription') || lowerName.contains('rx')) {
      return DocumentType.prescription;
    } else if (lowerName.contains('referral')) {
      return DocumentType.referralLetter;
    } else if (lowerName.contains('record') || lowerName.contains('history')) {
      return DocumentType.medicalRecord;
    }
    return DocumentType.other;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Add Document',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select existing photos',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            SizedBox(height: 12.h),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Capture a new document',
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            SizedBox(height: 12.h),
            _buildOptionTile(
              icon: Icons.file_present_rounded,
              title: 'Browse Files',
              subtitle: 'PDF, DOC, Images',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Medical Documents',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.attachments.length < widget.maxFiles)
              TextButton.icon(
                onPressed: _showAttachmentOptions,
                icon: Icon(Icons.add_rounded, size: 18.sp),
                label: Text(
                  'Add',
                  style: TextStyle(fontSize: 14.sp),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        
        // Description
        Text(
          'Attach relevant medical documents like lab results, prescriptions, or imaging reports.',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.grey500,
          ),
        ),
        SizedBox(height: 12.h),

        // Attachments list or empty state
        if (widget.attachments.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: [
              ...widget.attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _buildAttachmentCard(attachment, index),
                );
              }),
              SizedBox(height: 8.h),
              // File count and limit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.attachments.length}/${widget.maxFiles} files',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  Text(
                    'Max ${widget.maxFileSizeMB}MB per file',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _showAttachmentOptions,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.grey300,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.grey400,
              size: 32.sp,
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to upload documents',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                Text(
                  'PDF, Images up to ${widget.maxFileSizeMB}MB',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(PendingDocumentAttachment attachment, int index) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File icon/preview
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _getTypeColor(attachment.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: attachment.isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      File(attachment.localPath),
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      attachment.type.icon,
                      style: TextStyle(fontSize: 22.sp),
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    // Document type dropdown
                    GestureDetector(
                      onTap: () => _showTypeSelector(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getTypeColor(attachment.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              attachment.type.displayName,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _getTypeColor(attachment.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16.sp,
                              color: _getTypeColor(attachment.type),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      attachment.formattedSize,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: () => _removeAttachment(index),
            icon: Icon(
              Icons.close_rounded,
              size: 20.sp,
              color: AppColors.grey400,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
          ),
        ],
      ),
    );
  }

  void _showTypeSelector(int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Document Type',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...DocumentType.values.map((type) => ListTile(
              leading: Text(type.icon, style: TextStyle(fontSize: 24.sp)),
              title: Text(type.displayName),
              trailing: widget.attachments[index].type == type
                  ? Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                _updateDocumentType(index, type);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.medicalRecord:
        return AppColors.primary;
      case DocumentType.labResult:
        return AppColors.secondary;
      case DocumentType.prescription:
        return AppColors.success;
      case DocumentType.imaging:
        return AppColors.info;
      case DocumentType.referralLetter:
        return AppColors.warning;
      case DocumentType.other:
        return AppColors.grey500;
    }
  }
}
