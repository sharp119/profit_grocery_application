import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'services/asset_cache_service.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_event.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_event.dart';
import 'package:profit_grocery_application/services/session_manager_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import 'core/di/cart_injection.dart';
import 'core/network/network_info.dart';
import 'data/datasources/firebase/coupon/coupon_remote_datasource.dart';
import 'data/repositories/coupon/coupon_repository_impl.dart';
import 'domain/repositories/coupon_repository.dart';
import 'firebase_options.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/errors/global_error_handler.dart';
import 'core/routing/app_router.dart';
import 'services/otp_service.dart';
import 'services/session_manager.dart';
import 'services/session_manager_firestore.dart';
import 'services/cart/cart_initializer.dart';
import 'services/cart/home_cart_bridge.dart';
import 'services/user_service.dart';
import 'services/user_service_hybrid.dart';
import 'services/user_service_interface.dart';
import 'services/service_factory.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/firestore/auth_repository_firestore_impl.dart';
import 'data/repositories/firestore/user_repository_firestore_impl.dart';
import 'data/repositories/firestore/order_repository_impl.dart';
import 'domain/repositories/order_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
import 'presentation/blocs/orders/orders_bloc.dart';
import 'presentation/pages/authentication/splash_screen.dart';

// GetIt instance for dependency injection
final GetIt sl = GetIt.instance;

// Coupon dependencies initialization
Future<void> initCouponDependencies() async {
  // Network info
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  }
  
  // Data source
  sl.registerLazySingleton<CouponRemoteDataSource>(
    () => CouponRemoteDataSourceImpl(
      database: sl<FirebaseDatabase>(),
      remoteConfig: sl<FirebaseRemoteConfig>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(
      remoteDataSource: sl<CouponRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      remoteConfig: sl<FirebaseRemoteConfig>(),
    ),
  );
}

// Convenience method to get the current user ID
Future<String?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.userTokenKey);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Database persistence is now handled in CartRemoteDataSourceImpl
  // to ensure it's only called once and properly tracked
  
  // Setup Firebase Remote Config
  await setupRemoteConfig();
  
  // Setup dependency injection
  await setupDependencyInjection();
  
  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize asset cache service
  await AssetCacheService().initialize();
  
  // Run the cart initializer to ensure cart is loaded at startup
  await sl<CartInitializer>().initialize();
  
  print('App initialized - starting with MyApp');
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
    // Add a new default for database preference
    'prefer_firestore': true,
  });
  
  await remoteConfig.fetchAndActivate();
}

Future<void> setupDependencyInjection() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Firebase services
  sl.registerLazySingleton(() => FirebaseDatabase.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseRemoteConfig.instance);
  
  // Basic services
  sl.registerLazySingleton(() => OTPService());
  
  // Cart dependencies
  await initCartDependencies();
  
  // Coupon dependencies
  await initCouponDependencies();
  
  // Determine database preference from Remote Config
  final remoteConfig = FirebaseRemoteConfig.instance;
  final preferFirestore = remoteConfig.getBool('prefer_firestore');
  
  // Initialize repository factory
  final repositoryFactory = RepositoryFactory(
    firestore: FirebaseFirestore.instance,
    realtimeDatabase: FirebaseDatabase.instance,
    sharedPreferences: sharedPreferences,
    otpService: OTPService(),
    preferFirestore: preferFirestore,
  );
  
  // Register repositories
  if (preferFirestore) {
    // Initialize Firestore session manager
    final sessionManagerFirestore = SessionManagerFirestore();
    sessionManagerFirestore.setSharedPreferences(sharedPreferences);
    sessionManagerFirestore.setFirestore(FirebaseFirestore.instance);
    await sessionManagerFirestore.init();
    sl.registerLazySingleton<ISessionManager>(() => sessionManagerFirestore);
    sl.registerLazySingleton<SessionManagerFirestore>(() => sessionManagerFirestore);
    
    // Register Firestore repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryFirestoreImpl(
        otpService: sl<OTPService>(),
        sharedPreferences: sharedPreferences,
        firestore: FirebaseFirestore.instance,
        realtimeDatabase: FirebaseDatabase.instance,
        sessionManager: sessionManagerFirestore,
      ),
    );
    
    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryFirestoreImpl(
        firestore: FirebaseFirestore.instance,
        sharedPreferences: sharedPreferences,
        sessionManager: sessionManagerFirestore,
      ),
    );
  } else {
    // Initialize RTDB session manager
    final sessionManager = SessionManager();
    sessionManager.setSharedPreferences(sharedPreferences);
    sessionManager.setFirebaseDatabase(FirebaseDatabase.instance);
    await sessionManager.init();
    sl.registerLazySingleton<ISessionManager>(() => sessionManager);
    sl.registerLazySingleton<SessionManager>(() => sessionManager);
    
    // Register RTDB repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        otpService: sl<OTPService>(),
        sharedPreferences: sharedPreferences,
        firebaseDatabase: FirebaseDatabase.instance,
        sessionManager: sessionManager,
      ),
    );
    
    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        firebaseDatabase: FirebaseDatabase.instance,
        sharedPreferences: sharedPreferences,
        sessionManager: sessionManager,
      ),
    );
  }
  
  // Create hybrid user service via factory
  final userService = await repositoryFactory.createUserService();
  
  // Check the type for proper registration
  if (userService is UserServiceHybrid) {
    // Register concrete implementation
    sl.registerLazySingleton<UserServiceHybrid>(() => userService as UserServiceHybrid);
  }
  
  // Register interface
  sl.registerLazySingleton<IUserService>(() => userService);
  
  // Create and register a separate UserService instance for backward compatibility
  // This fixes the "GetIt: Object/factory with type UserService is not registered" error
  final rtdbUserService = UserService();
  await rtdbUserService.init(
    firebaseDatabase: FirebaseDatabase.instance,
    sharedPreferences: sharedPreferences,
  );
  sl.registerLazySingleton<UserService>(() => rtdbUserService);
  
  // Register order repository implementation
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(),
  );
  
  // Coupon dependencies are already initialized earlier
  
  // BLoCs
  sl.registerFactory(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  
  sl.registerFactory(
    () => UserBloc(userRepository: sl<UserRepository>()),
  );
  
  sl.registerFactory(
    () => OrdersBloc(orderRepository: sl<OrderRepository>()),
  );

  sl.registerFactory(
    () => NavigationBloc(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<UserBloc>(
          create: (context) {
            // Get the UserBloc instance
            final userBloc = sl<UserBloc>();
            
            // Try to load user data from SharedPreferences
            final prefs = sl<SharedPreferences>();
            final userId = prefs.getString(AppConstants.userTokenKey);
            
            // If we have a userId, load the user profile
            if (userId != null && userId.isNotEmpty) {
              userBloc.add(LoadUserProfileEvent(userId));
            }
            
            return userBloc;
          },
        ),
        BlocProvider<OrdersBloc>(
          create: (context) => sl<OrdersBloc>(),
        ),
        BlocProvider<NavigationBloc>(
          create: (context) => sl<NavigationBloc>(),
        ),
        BlocProvider<CartBloc>(
          create: (context) {
            // Create and initialize cart bloc
            final cartBloc = sl<CartBloc>();
            
            // Get current user ID and if valid, load cart data
            final prefs = sl<SharedPreferences>();
            final userId = prefs.getString(AppConstants.userTokenKey);
            
            if (userId != null && userId.isNotEmpty) {
              // Load cart data when the app starts
              cartBloc.add(const LoadCart());
            }
            
            return cartBloc;
          },
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
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppConstants.splashRoute,
          );
        },
      ),
    );
  }
}