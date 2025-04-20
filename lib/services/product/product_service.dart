import 'package:get_it/get_it.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../services/logging_service.dart';

/// Service for product-related operations
class ProductService {
  final ProductRepository _repository;
  
  ProductService({ProductRepository? repository})
      : _repository = repository ?? GetIt.instance<ProductRepository>();
  
  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      return await _repository.getAllProducts();
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting all products: $e');
      return [];
    }
  }
  
  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _repository.getProductById(productId);
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting product $productId: $e');
      return null;
    }
  }
  
  /// Get products in a category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      return await _repository.getProductsByCategory(categoryId);
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting products for category $categoryId: $e');
      return [];
    }
  }
  
  /// Get products in a subcategory
  Future<List<Product>> getProductsBySubcategory(String categoryId, String subcategoryId) async {
    try {
      return await _repository.getProductsBySubcategory(categoryId, subcategoryId);
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting products for subcategory $categoryId/$subcategoryId: $e');
      return [];
    }
  }
  
  /// Get bestseller products
  Future<List<Product>> getBestsellerProducts() async {
    try {
      return await _repository.getBestsellerProducts();
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting bestseller products: $e');
      return [];
    }
  }
  
  /// Get similar products
  Future<List<Product>> getSimilarProducts(String productId, {int limit = 3}) async {
    try {
      return await _repository.getSimilarProducts(productId, limit: limit);
    } catch (e) {
      LoggingService.logError('ProductService', 'Error getting similar products for $productId: $e');
      return [];
    }
  }
}