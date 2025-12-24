import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'config/theme.dart';
import 'constants/routes.dart';
import 'core/util/auth_guard.dart';
import 'core/util/route_guard.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Import screens from new locations
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';
import 'features/users/presentation/pages/users_screen.dart';
import 'features/users/presentation/pages/user_details_screen.dart';
import 'features/users/presentation/pages/add_user_screen.dart';
import 'features/users/presentation/pages/edit_user_screen.dart';
import 'features/statistics/presentation/pages/statistics_screen.dart';
import 'features/statistics/presentation/pages/advanced_statistics_screen.dart';
import 'features/settings/presentation/pages/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependency injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus())),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        // Add other blocs as needed
      ],
      child: const AppWithTheme(),
    );
  }
}

class AppWithTheme extends StatelessWidget {
  const AppWithTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design size based on a standard desktop design
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return MaterialApp(
              title: 'Admin Dashboard',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light, // You can make this dynamic if needed
              initialRoute:
                  state is Authenticated
                      ? AppRoutes.dashboard
                      : AppRoutes.login,
              routes: {
                // Public routes
                AppRoutes.login: (context) => const LoginScreen(),

                // Admin only routes - restrict all access to just admin
                AppRoutes.dashboard:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: DashboardScreen(),
                    ),
                AppRoutes.users:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: UsersScreen(),
                    ),
                AppRoutes.userDetails:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: UserDetailsScreen(),
                    ),
                AppRoutes.addUser:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: AddUserScreen(),
                    ),
                AppRoutes.editUser:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: EditUserScreen(),
                    ),
                AppRoutes.statistics:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: StatisticsScreen(),
                    ),
                AppRoutes.advancedStatistics:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: AdvancedStatisticsScreen(),
                    ),
                AppRoutes.settings:
                    (context) => const RouteGuard(
                      allowedRoles: AuthGuard.adminOnlyRoles,
                      child: SettingsScreen(),
                    ),
              },
            );
          },
        );
      },
    );
  }
}
