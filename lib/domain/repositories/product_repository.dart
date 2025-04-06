import 'package:dartz/dartz.dart';

import '../entities/product.dart';
import '../../core/errors/failures.dart';

abstract class ProductRepository {
  /// Get all products
  Future<Either<Failure, List<Product>>> getProducts({
    bool activeOnly = true,
  });
  
  /// Get a single product by ID
  Future<Either<Failure, Product>> getProductById(String productId);
  
  /// Get products by category ID
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  });
  
  /// Get products by subcategory ID
  Future<Either<Failure, List<Product>>> getProductsBySubcategory(
    String subcategoryId, {
    bool activeOnly = true,
  });
  
  /// Get featured products
  Future<Either<Failure, List<Product>>> getFeaturedProducts();
  
  /// Get best seller products
  Future<Either<Failure, List<Product>>> getBestSellerProducts();
  
  /// Search products by keyword
  Future<Either<Failure, List<Product>>> searchProducts(
    String keyword, {
    bool activeOnly = true,
  });
}