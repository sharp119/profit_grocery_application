import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/local_cart_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../services/cart/cart_initializer.dart';
import '../../services/cart/cart_sync_service.dart';
import '../../services/cart/unified_cart_service.dart';

final sl = GetIt.instance;

Future<void> initCartDependencies() async {
  // Local data source for caching
  sl.registerLazySingleton<LocalCartDataSource>(
    () => LocalCartDataSource(
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      database: sl<FirebaseDatabase>(),
      localCartDataSource: sl<LocalCartDataSource>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Services
  // For backward compatibility, but using the new implementation under the hood
  final cartSyncService = CartSyncService(
    cartRepository: sl<CartRepository>(),
    sharedPreferences: sl<SharedPreferences>(),
    database: sl<FirebaseDatabase>(),
  );
  
  // Register the cart sync service
  sl.registerLazySingleton<CartSyncService>(() => cartSyncService);
  
  // Register the unified cart service (it's a singleton itself, but register for DI)
  final unifiedCartService = UnifiedCartService();
  unifiedCartService.initialize();
  sl.registerLazySingleton<UnifiedCartService>(() => unifiedCartService);

  // BLoC
  sl.registerFactory(
    () => CartBloc(
      cartRepository: sl<CartRepository>(),
      cartSyncService: sl<CartSyncService>(),
    ),
  );
  
  // Cart Initializer - create last after CartBloc is registered
  sl.registerLazySingleton<CartInitializer>(
    () => CartInitializer(
      cartBloc: sl<CartBloc>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );
}
