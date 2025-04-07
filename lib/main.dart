import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'services/otp_service.dart';
import 'services/session_manager.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/pages/authentication/phone_entry_page.dart';
import 'presentation/pages/authentication/otp_verification_page.dart';
import 'presentation/pages/authentication/splash_screen.dart';
import 'presentation/pages/authentication/user_registration_page.dart';
import 'presentation/pages/home/home_page.dart';

// GetIt instance for dependency injection
final GetIt sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization
  await Firebase.initializeApp();
  
  // Setup Firebase Remote Config
  await setupRemoteConfig();
  
  // Setup dependency injection
  await setupDependencyInjection();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

Future<void> setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  
  await remoteConfig.setDefaults({
    AppConstants.featuredCategoriesKey: jsonEncode([]),
    AppConstants.appMaintenanceKey: false,
    AppConstants.minAppVersionKey: '1.0.0',
  });
  
  await remoteConfig.fetchAndActivate();
}

Future<void> setupDependencyInjection() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Firebase services
  sl.registerLazySingleton(() => FirebaseDatabase.instance);
  sl.registerLazySingleton(() => FirebaseRemoteConfig.instance);
  
  // Services
  sl.registerLazySingleton(() => OTPService());
  
  // Initialize SessionManager as a singleton with proper dependencies
  final sessionManager = SessionManager();
  await sessionManager.init(
    sharedPreferences: sharedPreferences,
    firebaseDatabase: FirebaseDatabase.instance,
  );
  sl.registerLazySingleton(() => sessionManager);
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      otpService: sl(),
      sharedPreferences: sl(),
      firebaseDatabase: sl(),
    ),
  );
  
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      firebaseDatabase: sl(),
      sharedPreferences: sl(),
      sessionManager: sl(),
    ),
  );
  
  // BLoCs
  sl.registerFactory(
    () => AuthBloc(authRepository: sl()),
  );
  
  sl.registerFactory(
    () => UserBloc(userRepository: sl()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>(),
        ),
        BlocProvider<UserBloc>(
          create: (context) => sl<UserBloc>(),
        ),
      ],
      child: ScreenUtilInit(
        // Use more flexible approach with adaptive design size
        designSize: const Size(390, 844), // Based on iPhone 14/15
        minTextAdapt: true,
        splitScreenMode: true,
        // Better adaptive builder
        builder: (context, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
            routes: {
              AppConstants.homeRoute: (context) => const HomePage(),
              AppConstants.loginRoute: (context) => const PhoneEntryPage(),
              // Add more routes as we develop
            },
          );
        },
      ),
    );
  }
}