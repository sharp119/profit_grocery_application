import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/firebase/cart/cart_remote_datasource.dart';
import '../../data/datasources/firebase/coupon/coupon_remote_datasource.dart';
import '../../data/datasources/local/cart_local_datasource.dart';
import '../../data/repositories/cart/cart_repository_impl.dart';
import '../../data/repositories/coupon/coupon_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../services/cart/cart_sync_service.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> initCartDependencies() async {
  // Network info
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  }

  // Register Connectivity instance
  if (!sl.isRegistered<Connectivity>()) {
    sl.registerLazySingleton<Connectivity>(() => Connectivity());
  }

  // Data sources
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(
      database: sl<FirebaseDatabase>(),
    ),
  );
  
  sl.registerLazySingleton<CouponRemoteDataSource>(
    () => CouponRemoteDataSourceImpl(
      database: sl<FirebaseDatabase>(),
      remoteConfig: sl<FirebaseRemoteConfig>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(
      remoteDataSource: sl<CouponRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      remoteConfig: sl<FirebaseRemoteConfig>(),
    ),
  );
  
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      remoteDataSource: sl<CartRemoteDataSource>(),
      localDataSource: sl<CartLocalDataSource>(),
      couponRepository: sl<CouponRepository>(),
      networkInfo: sl<NetworkInfo>(),
      remoteConfig: sl<FirebaseRemoteConfig>(),
    ),
  );

  // Services
  final cartSyncService = CartSyncService(
    cartRepository: sl<CartRepository>(),
    sharedPreferences: sl<SharedPreferences>(),
    database: sl<FirebaseDatabase>(),
    connectivity: sl<Connectivity>(),
  );
  
  // Initialize the cart sync service
  await cartSyncService.init();
  
  // Register the cart sync service
  sl.registerLazySingleton<CartSyncService>(() => cartSyncService);

  // BLoC
  sl.registerFactory(
    () => CartBloc(
      cartRepository: sl<CartRepository>(),
    ),
  );
}
