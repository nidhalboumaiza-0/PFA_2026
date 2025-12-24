import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/reset_password_screen.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:medical_app/features/authentication/domain/usecases/verify_email_use_case.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init() async {
    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }

    // Listen for new links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint('DeepLinkService: Error listening to links: $err');
      },
    );
  }

  void _handleLink(Uri uri) {
    debugPrint('DeepLinkService: Handling link: $uri');
    
    // Scheme: esante://
    if (uri.scheme != 'esante') return;

    // Host: verify-email or reset-password
    final path = uri.host; // For custom schemes, the host is often the first part after //
    final params = uri.queryParameters;
    final token = params['token'];

    if (token == null || token.isEmpty) {
      debugPrint('DeepLinkService: Token missing in link');
      return;
    }

    if (path == 'verify-email') {
      _handleEmailVerification(token);
    } else if (path == 'reset-password') {
      _handlePasswordReset(token, params['email'] ?? '');
    }
  }

  void _handleEmailVerification(String token) async {
    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final verifyEmailUseCase = di.sl<VerifyEmailUseCase>();
      final result = await verifyEmailUseCase(token);

      // Close loading dialog
      if (Get.isDialogOpen ?? false) Get.back();

      result.fold(
        (failure) {
          if (Get.context != null) {
            showErrorSnackBar(
              Get.context!,
              "Email verification failed: ${failure.message}",
            );
          }
          Get.offAll(() => const LoginScreen());
        },
        (_) {
          if (Get.context != null) {
            showSuccessSnackBar(
              Get.context!,
              "Email verified successfully! Please login.",
            );
          }
          Get.offAll(() => const LoginScreen());
        },
      );
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) Get.back();
      
      if (Get.context != null) {
        showErrorSnackBar(
          Get.context!,
          "An error occurred during verification: $e",
        );
      }
      Get.offAll(() => const LoginScreen());
    }
  }

  void _handlePasswordReset(String token, String email) {
    Get.to(() => ResetPasswordScreen(
      email: email, // We might not have email in the link, handle gracefully
      token: token,
    ));
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
