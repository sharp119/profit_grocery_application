import 'package:dartz/dartz.dart';

import '../entities/product.dart';
import '../../core/errors/failures.dart';

abstract class ProductRepository {
  /// Get all products with optional filtering and pagination
  Future<Either<Failure, List<Product>>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? subcategoryId,
    bool? inStock,
    bool? featured,
  });
  
  /// Get a single product by ID
  Future<Either<Failure, Product>> getProductById(String productId);
  
  /// Search products by name
  Future<Either<Failure, List<Product>>> searchProducts(
    String query, {
    int? limit,
    int? offset,
  });
  
  /// Get featured products
  Future<Either<Failure, List<Product>>> getFeaturedProducts({
    int? limit,
  });
  
  /// Get products by category
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId, {
    int? limit,
    int? offset,
  });
  
  /// Get products by subcategory
  Future<Either<Failure, List<Product>>> getProductsBySubcategory(
    String subcategoryId, {
    int? limit,
    int? offset,
  });
}