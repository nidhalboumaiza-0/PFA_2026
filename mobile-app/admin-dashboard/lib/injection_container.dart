import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/network/network_info.dart';

// Auth
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/is_logged_in_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Dashboard
import 'features/dashboard/data/datasources/stats_remote_data_source.dart';
import 'features/dashboard/data/repositories/stats_repository_impl.dart';
import 'features/dashboard/domain/repositories/stats_repository.dart';
import 'features/dashboard/domain/usecases/get_appointments_per_day_usecase.dart';
import 'features/dashboard/domain/usecases/get_appointments_per_month_usecase.dart';
import 'features/dashboard/domain/usecases/get_appointments_per_year_usecase.dart';
import 'features/dashboard/domain/usecases/get_stats_usecase.dart';
import 'features/dashboard/domain/usecases/get_top_doctors_by_completed_appointments_usecase.dart';
import 'features/dashboard/domain/usecases/get_top_doctors_by_cancelled_appointments_usecase.dart';
import 'features/dashboard/domain/usecases/get_top_patients_by_cancelled_appointments_usecase.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      isLoggedInUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => IsLoggedInUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Dashboard
  // Bloc
  sl.registerFactory(
    () => DashboardBloc(
      getStatsUseCase: sl(),
      getAppointmentsPerDayUseCase: sl(),
      getAppointmentsPerMonthUseCase: sl(),
      getAppointmentsPerYearUseCase: sl(),
      getTopDoctorsByCompletedAppointmentsUseCase: sl(),
      getTopDoctorsByCancelledAppointmentsUseCase: sl(),
      getTopPatientsByCancelledAppointmentsUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentsPerDayUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentsPerMonthUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentsPerYearUseCase(sl()));
  sl.registerLazySingleton(
    () => GetTopDoctorsByCompletedAppointmentsUseCase(sl()),
  );
  sl.registerLazySingleton(
    () => GetTopDoctorsByCancelledAppointmentsUseCase(sl()),
  );
  sl.registerLazySingleton(
    () => GetTopPatientsByCancelledAppointmentsUseCase(sl()),
  );

  // Repository
  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(firestore: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}
