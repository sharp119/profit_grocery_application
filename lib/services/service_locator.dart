import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for FirebaseFirestore
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/data/repositories/bestseller_repository_simple.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart';
import 'package:profit_grocery_application/services/product/shared_product_service.dart';

// Imports for Order Feature
import 'package:profit_grocery_application/data/datasources/firebase/order_remote_datasource.dart';
import 'package:profit_grocery_application/data/repositories/order_repository_impl.dart';
import 'package:profit_grocery_application/domain/repositories/order_repository.dart';
// Corrected path based on your previous snippets for CreateOrderUsecase
import 'package:profit_grocery_application/domain/usecases/order/create_order_usecase.dart';
import 'package:profit_grocery_application/services/rtdb_product_service.dart';

// NEW: Import GetOrdersUseCase and OrdersBloc
import 'package:profit_grocery_application/domain/usecases/order/get_orders_usecase.dart'; //
import 'package:profit_grocery_application/presentation/blocs/orders/orders_bloc.dart'; //


// Define 'sl' (service locator) globally for this file and for export
final sl = GetIt.instance; // <--- ADD THIS LINE AT THE TOP LEVEL

/// Initialize services and repositories in the GetIt service locator
void setupServiceLocator() {
 // Now use the global 'sl' instead of a local 'getIt'
// final getIt = GetIt.instance; // <--- REMOVE OR COMMENT OUT THIS LINE

 // --- Core Firebase Services (Prerequisite for Order Feature) ---
 if (!sl.isRegistered<FirebaseFirestore>()) { // <--- USE sl HERE
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance); // <--- USE sl HERE
 }

 // --- Existing Registrations ---
 // Register services
 sl.registerLazySingleton<SharedProductService>(() => SharedProductService()); // <--- USE sl HERE
 sl.registerLazySingleton<SharedCategoryService>(() => SharedCategoryService()); // <--- USE sl HERE

 // Register repositories
 sl.registerLazySingleton<BestsellerRepositorySimple>(() => BestsellerRepositorySimple()); // <--- USE sl HERE

 // --- New Registrations for Order Feature ---
 // Data Sources for Order
 sl.registerLazySingleton<OrderRemoteDataSource>( //
  () => OrderRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
 );

 // Repositories for Order
 sl.registerLazySingleton<OrderRepository>( //
  () => OrderRepositoryImpl(remoteDataSource: sl<OrderRemoteDataSource>()),
 );

 // Usecases for Order
 sl.registerLazySingleton<CreateOrderUsecase>( //
  () => CreateOrderUsecase(sl<OrderRepository>()),
 );

  // NEW: Register GetOrdersUseCase
  sl.registerLazySingleton<GetOrdersUseCase>(
    () => GetOrdersUseCase(sl<OrderRepository>()),
  );

 sl.registerLazySingleton<RTDBProductService>(() => RTDBProductService());

 sl.registerLazySingleton<FirestoreProductService>(() => FirestoreProductService());

  // NEW: Register OrdersBloc
  sl.registerFactory<OrdersBloc>(
    () => OrdersBloc(getOrdersUseCase: sl<GetOrdersUseCase>()),
  );
}