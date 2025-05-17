import 'package:get_it/get_it.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/product_repository.dart';
import '../../data/repositories/firestore/product/product_repository_impl.dart';
import '../../services/product/product_service.dart';
import '../../services/product/product_dynamic_data_provider.dart';

final GetIt sl = GetIt.instance;

/// Initialize product-related dependencies
Future<void> initProductDependencies() async {
  // Register Product Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  
  // Register Product Service
  sl.registerLazySingleton<ProductService>(
    () => ProductService(
      repository: sl<ProductRepository>(),
    ),
  );

  // Register ProductDynamicDataProvider for real-time product data from RTDB
  // only if it's not already registered
  if (!sl.isRegistered<ProductDynamicDataProvider>()) {
    sl.registerLazySingleton<ProductDynamicDataProvider>(
      () => ProductDynamicDataProvider(),
    );
  }
}