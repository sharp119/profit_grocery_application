import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';
import 'dart:math';

import '../../domain/entities/product.dart';
import '../../services/product/shared_product_service.dart';
import '../../services/logging_service.dart';

/// Repository for bestseller product operations with enhanced functionality.
/// Provides methods to get bestseller products with options for limiting and ranking.
class BestsellerRepository {
  final FirebaseFirestore _firestore;
  final SharedProductService _productService;
  
  BestsellerRepository({
    FirebaseFirestore? firestore,
    SharedProductService? productService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _productService = productService ?? SharedProductService();
  
  /// Get bestseller products with options for limit and ranking
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of products to return (default: 6)
  /// - [ranked]: Whether to sort products by rank or randomize (default: true)
  ///
  /// When [ranked] is true, products are sorted by the rank field.
  /// When [ranked] is false, products are randomly selected from available bestsellers.
  Future<List<Product>> getBestsellerProducts({
    int limit = 12,
    bool ranked = false,
  }) async {
    try {
      LoggingService.logFirestore('BESTSELLER_REPO: Starting to get bestseller products (limit: $limit, ranked: $ranked)');
      print('BESTSELLER_REPO: Starting to get bestseller products (limit: $limit, ranked: $ranked)');
      
      // Get all bestsellers from the bestsellers collection
      QuerySnapshot bestsellersSnapshot;
      
      if (ranked) {
        // Get bestsellers sorted by rank
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .orderBy('rank')
            .limit(limit)
            .get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers from Firestore');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers from Firestore');
      } else {
        // Get all bestsellers, we'll randomize later
        bestsellersSnapshot = await _firestore.collection('bestsellers').get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization from Firestore');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization from Firestore');
      }
      
      // Extract product IDs from the bestseller documents
      List<String> productIds = [];
      Map<String, int> productRanks = {};
      
      // Detailed logging of bestseller documents
      LoggingService.logFirestore('BESTSELLER_REPO: Processing bestseller documents:');
      print('BESTSELLER_REPO: Processing bestseller documents:');
      
      for (final doc in bestsellersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String?;
        final rank = data['rank'] as int? ?? 999; // Default high rank if missing
        
        if (productId != null && productId.isNotEmpty) {
          productIds.add(productId);
          productRanks[productId] = rank;
          
          // Enhanced logging with document details
          final refPath = data['ref'] as String? ?? 'No reference path';
          print('BESTSELLER_REPO: Doc ${doc.id} => Product ID: $productId, Rank: $rank, Ref: $refPath');
          LoggingService.logFirestore('BESTSELLER_REPO: Doc ${doc.id} => Product ID: $productId, Rank: $rank, Ref: $refPath');
        } else {
          print('BESTSELLER_REPO: Warning - Bestseller doc ${doc.id} has no valid productId');
          LoggingService.logFirestore('BESTSELLER_REPO: Warning - Bestseller doc ${doc.id} has no valid productId');
        }
      }
      
      if (!ranked && productIds.length > limit) {
        // Randomize and limit the product IDs
        productIds.shuffle(Random());
        productIds = productIds.take(limit).toList();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Randomized and limited to $limit products');
        print('BESTSELLER_REPO: Randomized and limited to $limit products');
      }
      
      // Get full product details for these IDs
      final List<Product> products = [];
      
      LoggingService.logFirestore('BESTSELLER_REPO: Fetching detailed product information for ${productIds.length} products');
      print('BESTSELLER_REPO: Fetching detailed product information for ${productIds.length} products');
      
      for (final productId in productIds) {
        print('BESTSELLER_REPO: Fetching product details for ID: $productId (Rank: ${productRanks[productId] ?? "unknown"})');
        LoggingService.logFirestore('BESTSELLER_REPO: Fetching product details for ID: $productId (Rank: ${productRanks[productId] ?? "unknown"})');
        
        final product = await _productService.getProductById(productId);
        if (product != null) {
          products.add(product);
          
          // Enhanced logging with category information
          final categoryInfo = 'Category: ${product.categoryName ?? "Unknown"}, ID: ${product.categoryId ?? "Unknown"}, Subcategory: ${product.subcategoryId ?? "Unknown"}';
          print('BESTSELLER_REPO: Found product ${product.id} (${product.name}) - $categoryInfo');
          LoggingService.logFirestore('BESTSELLER_REPO: Found product ${product.id} (${product.name}) - $categoryInfo');
          
          // Try to get category group information
          try {
            final categoryService = SharedCategoryService();
            if (product.categoryName != null) {
              final categoryGroup = await categoryService.getCategoryById(product.categoryName!);
              if (categoryGroup != null) {
                // Log category group information
                final categoryGroupInfo = 'CategoryGroup: ${categoryGroup.title} (${categoryGroup.id}), contains ${categoryGroup.items.length} subcategories';
                print('BESTSELLER_REPO: ${product.name} belongs to $categoryGroupInfo');
                LoggingService.logFirestore('BESTSELLER_REPO: ${product.name} belongs to $categoryGroupInfo');
              }
            }
          } catch (e) {
            // Just log the error, don't interrupt the product fetching
            LoggingService.logError('BESTSELLER_REPO', 'Error getting category group info: $e');
          }
        } else {
          print('BESTSELLER_REPO: Warning - Product not found for ID: $productId');
          LoggingService.logFirestore('BESTSELLER_REPO: Warning - Product not found for ID: $productId');
        }
      }
      
      LoggingService.logFirestore('BESTSELLER_REPO: Returning ${products.length} bestseller products with full details');
      print('BESTSELLER_REPO: Returning ${products.length} bestseller products with full details');
      return products;
    } catch (e) {
      LoggingService.logError('BESTSELLER_REPO', 'Error getting bestseller products: $e');
      print('BESTSELLER_REPO ERROR: Failed to get bestseller products - $e');
      return [];
    }
  }
}
