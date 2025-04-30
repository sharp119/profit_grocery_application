import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/local_cart_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../services/simple_cart_service.dart';
import '../../services/cart_provider.dart';

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

  // Register SimpleCartService (it's a singleton itself, but register for DI)
  sl.registerLazySingleton<SimpleCartService>(() => SimpleCartService());

  // Register CartProvider (it's a singleton itself, but register for DI)
  sl.registerLazySingleton<CartProvider>(() => CartProvider());

  // BLoC
  sl.registerFactory(
    () => CartBloc(
      cartRepository: sl<CartRepository>(),
      simpleCartService: sl<SimpleCartService>(),
    ),
  );
}
