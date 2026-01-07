import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/connection_banner.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/messaging/presentation/bloc/messaging_bloc.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize dependencies
  await di.initializeDependencies();

  // Initialize push notifications (OneSignal)
  await PushNotificationService().initialize();

  runApp(const ESanteApp());
}

class ESanteApp extends StatelessWidget {
  const ESanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design size based on standard mobile design (iPhone 14 Pro)
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (_) => di.sl<AuthBloc>(),
            ),
            BlocProvider<MessagingBloc>(
              create: (_) => di.sl<MessagingBloc>(),
            ),
          ],
          child: MaterialApp(
            title: 'eSanté',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              // Wrap entire app with connection banner for global offline notification
              return ConnectionBanner(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
