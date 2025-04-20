import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart';

/// Register all Firestore-related services with the GetIt instance
class FirestoreServiceModule {
  static void register(GetIt getIt) {
    // Register FirestoreProductService as a singleton
    getIt.registerLazySingleton<FirestoreProductService>(
      () => FirestoreProductService(),
    );
  }
}