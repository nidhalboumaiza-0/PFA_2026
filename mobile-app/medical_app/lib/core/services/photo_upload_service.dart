import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/services/api_service.dart';

/// Service for handling profile photo upload functionality.
/// Uses image_picker to select photos and ApiService to upload to backend.
class PhotoUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Shows a bottom sheet with options to take a photo or choose from gallery.
  /// [context] - The BuildContext for showing the bottom sheet
  /// [onPhotoUploaded] - Callback with the new photo URL when upload succeeds
  static void showPhotoOptions(
    BuildContext context,
    Function(String newPhotoUrl) onPhotoUploaded,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Title
            Text(
              context.tr('photo_upload.change_photo'),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),

            // Take Photo option
            _buildOption(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: context.tr('photo_upload.take_photo'),
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(context, ImageSource.camera, onPhotoUploaded);
              },
            ),
            SizedBox(height: 12.h),

            // Choose from Gallery option
            _buildOption(
              context: context,
              icon: Icons.photo_library_outlined,
              label: context.tr('photo_upload.choose_from_gallery'),
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(context, ImageSource.gallery, onPhotoUploaded);
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _pickAndUploadPhoto(
    BuildContext context,
    ImageSource source,
    Function(String newPhotoUrl) onPhotoUploaded,
  ) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload to backend
      final result = await ApiService.uploadProfilePhoto(pickedFile.path);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true && result['photoUrl'] != null) {
        onPhotoUploaded(result['photoUrl']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('photo_upload.upload_success')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('photo_upload.upload_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
