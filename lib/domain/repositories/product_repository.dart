import '../entities/product.dart';

/// Interface for product repository
abstract class ProductRepository {
  /// Get all products across all categories
  Future<List<Product>> getAllProducts();
  
  /// Get a product by its ID
  Future<Product?> getProductById(String productId);
  
  /// Get products in a specific category
  Future<List<Product>> getProductsByCategory(String categoryId);
  
  /// Get products in a specific subcategory
  Future<List<Product>> getProductsBySubcategory(String categoryId, String subcategoryId);
  
  /// Get bestseller products
  Future<List<Product>> getBestsellerProducts();
  
  /// Get similar products to a specific product
  Future<List<Product>> getSimilarProducts(String productId, {int limit = 3});
}