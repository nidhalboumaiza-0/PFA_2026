import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'api_service.dart';

/// Service to handle profile photo selection and upload
class ProfilePhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Show a bottom sheet to choose between camera and gallery
  static Future<String?> showPhotoOptionsAndUpload(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoOptionsSheet(),
    );

    if (source == null) return null;

    return await _pickAndUploadPhoto(context, source);
  }

  /// Pick image from the specified source and upload it
  static Future<String?> _pickAndUploadPhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to server
      final result = await ApiService.uploadProfilePhoto(image.path);

      // Dismiss loading
      Navigator.of(context).pop();

      if (result['photoUrl'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('photo_uploaded_success')),
            backgroundColor: Colors.green,
          ),
        );
        return result['photoUrl'] as String;
      } else {
        throw Exception('No photo URL returned');
      }
    } catch (e) {
      // Dismiss loading if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('photo_upload_failed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Pick image without uploading (for preview)
  static Future<File?> pickImageOnly(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}

class _PhotoOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D44) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                context.tr('choose_photo_source'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text(
                context.tr('camera'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                context.tr('take_new_photo'),
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: Text(
                context.tr('gallery'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                context.tr('choose_from_gallery'),
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
