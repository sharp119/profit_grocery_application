import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/data/repositories/bestseller_repository.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';
import 'package:profit_grocery_application/services/product/shared_product_service.dart';

/// Initialize services and repositories in the GetIt service locator
void setupServiceLocator() {
  final getIt = GetIt.instance;
  
  // Register services
  getIt.registerLazySingleton<SharedProductService>(() => SharedProductService());
  getIt.registerLazySingleton<SharedCategoryService>(() => SharedCategoryService());
  
  // Register repositories
  getIt.registerLazySingleton<BestsellerRepository>(() => BestsellerRepository(
    productService: getIt<SharedProductService>(),
  ));
}
