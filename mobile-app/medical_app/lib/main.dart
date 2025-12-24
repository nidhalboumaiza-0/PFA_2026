import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/utils/app_themes.dart';
import 'package:medical_app/core/utils/theme_manager.dart';
import 'package:medical_app/core/l10n/app_localizations.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/authentication/presentation/blocs/Signup%20BLoC/signup_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/login%20BLoC/login_bloc.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/features/home/presentation/pages/home_medecin.dart';
import 'package:medical_app/features/home/presentation/pages/home_patient.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';

import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_cubit.dart';
import 'package:medical_app/firebase_options.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:provider/provider.dart';
import 'features/authentication/presentation/blocs/forget password bloc/forgot_password_bloc.dart';
import 'features/authentication/presentation/blocs/reset password bloc/reset_password_bloc.dart';
// import 'features/authentication/presentation/blocs/verify code bloc/verify_code_bloc.dart'; // DISABLED
import 'features/profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/dashboard/presentation/blocs/dashboard BLoC/dashboard_bloc.dart';
import 'features/ordonnance/presentation/bloc/prescription_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/logout_bloc/logout_bloc.dart';
import 'package:medical_app/core/services/deep_link_service.dart';

// Send notification using Express backend
Future<void> sendNotification({
  required String title,
  required String body,
  required String senderId,
  required String recipientId,
  required NotificationType type,
  String? appointmentId,
  String? prescriptionId,
  Map<String, dynamic>? data,
}) async {
  try {
    final Map<String, dynamic> requestData = {
      'title': title,
      'body': body,
      'senderId': senderId,
      'recipientId': recipientId,
      'type': NotificationUtils.notificationTypeToString(type),
    };

    if (appointmentId != null) {
      requestData['appointmentId'] = appointmentId;
    }

    if (prescriptionId != null) {
      requestData['prescriptionId'] = prescriptionId;
    }

    if (data != null) {
      requestData['data'] = data;
    }

    // Get token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('TOKEN');

    if (token == null) {
      throw ServerException(message: 'Authentication token not found');
    }

    final response = await http.post(
      Uri.parse(AppConstants.notificationsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestData),
    );

    if (response.statusCode == 201) {
      debugPrint('Notification sent successfully');
    } else {
      debugPrint(
        'Failed to send notification: ${response.statusCode}, ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('Error sending notification: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firebase reCAPTCHA verification (disable for testing)
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  // For testing purposes, disable App Check
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);

  // Firebase persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Initialize date formatting
  await initializeDateFormatting();

  // Initialize dependency injection
  await di.init();

  // Initialize Deep Link Service
  await DeepLinkService().init();

  // Initialize OneSignal
  final notificationBloc = di.sl<NotificationBloc>();
  notificationBloc.add(InitializeOneSignalEvent());

  // Get shared preferences instance
    final prefs = await SharedPreferences.getInstance();

  // Get user data from shared preferences
  final userId = prefs.getString('USER_ID');
  final userRole = prefs.getString('USER_ROLE');
  final isLoggedIn = prefs.getBool('IS_LOGGED_IN') ?? false;

  // Set external user ID in OneSignal if user is logged in
  if (isLoggedIn && userId != null) {
    notificationBloc.add(SetExternalUserIdEvent(userId: userId));
    notificationBloc.add(SaveOneSignalPlayerIdEvent(userId: userId));
  }

  // Create theme manager
  final themeManager = ThemeManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>(create: (_) => themeManager),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (context) => di.sl<ThemeCubit>()),
          BlocProvider<LoginBloc>(create: (context) => di.sl<LoginBloc>()),
          BlocProvider<SignupBloc>(create: (context) => di.sl<SignupBloc>()),
          BlocProvider<ToggleCubit>(create: (context) => di.sl<ToggleCubit>()),
          BlocProvider<ForgotPasswordBloc>(
            create: (context) => di.sl<ForgotPasswordBloc>(),
          ),
          // BlocProvider<VerifyCodeBloc>(
          //   create: (context) => di.sl<VerifyCodeBloc>(),
          // ),
          BlocProvider<ResetPasswordBloc>(
            create: (context) => di.sl<ResetPasswordBloc>(),
          ),
          BlocProvider<RendezVousBloc>(
            create: (context) => di.sl<RendezVousBloc>(),
          ),
          BlocProvider<UpdateUserBloc>(
            create: (context) => di.sl<UpdateUserBloc>(),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => di.sl<DashboardBloc>(),
          ),
          BlocProvider<PrescriptionBloc>(
            create: (context) => di.sl<PrescriptionBloc>(),
          ),
          BlocProvider<NotificationBloc>(create: (context) => notificationBloc),
          BlocProvider<RatingBloc>(create: (context) => di.sl<RatingBloc>()),
          BlocProvider<DossierMedicalBloc>(
            create: (context) => di.sl<DossierMedicalBloc>(),
          ),
          BlocProvider<LogoutBloc>(
            create: (context) => di.sl<LogoutBloc>(),
          ),
          BlocProvider<OnlineStatusCubit>(
            create: (context) => di.sl<OnlineStatusCubit>(),
          ),
        ],
        child: const ScreenUtilInit(designSize: Size(390, 844), child: MyApp()),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('USER_ID');
    final userRole = prefs.getString('USER_ROLE');
    final isLoggedIn = prefs.getBool('IS_LOGGED_IN') ?? false;

    setState(() {
      _isLoggedIn = isLoggedIn && userId != null;
      _userRole = userRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
              return GetMaterialApp(
          title: 'MediLink',
                debugShowCheckedModeBanner: false,
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
          themeMode: themeManager.themeMode,
          // Localization delegates
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          // Default route
          home:
              _isLoggedIn
                  ? _userRole == 'medecin'
                      ? const HomeMedecin()
                      : const HomePatient()
                  : const LoginScreen(),
        );
      },
    );
  }
}
