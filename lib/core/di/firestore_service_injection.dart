import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart';
import 'package:profit_grocery_application/utils/test/firestore_test_data_sync.dart';

/// Initialize Firestore service dependencies
Future<void> initFirestoreServiceDependencies(GetIt sl) async {
  // Register FirestoreProductService as a singleton
  if (!sl.isRegistered<FirestoreProductService>()) {
    sl.registerLazySingleton<FirestoreProductService>(
      () => FirestoreProductService(
        firestore: sl<FirebaseFirestore>(),
      ),
    );
  }
  
  // Register FirestoreTestDataSync as a factory (new instance each time)
  sl.registerFactory<FirestoreTestDataSync>(
    () => FirestoreTestDataSync(
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}