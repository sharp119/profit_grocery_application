import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    int limit = 6,
    bool ranked = true,
  }) async {
    try {
      LoggingService.logFirestore('BestsellerRepository: Getting bestseller products (limit: $limit, ranked: $ranked)');
      
      // Get all bestsellers from the bestsellers collection
      QuerySnapshot bestsellersSnapshot;
      
      if (ranked) {
        // Get bestsellers sorted by rank
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .orderBy('rank')
            .limit(limit)
            .get();
        
        LoggingService.logFirestore('BestsellerRepository: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
      } else {
        // Get all bestsellers, we'll randomize later
        bestsellersSnapshot = await _firestore.collection('bestsellers').get();
        
        LoggingService.logFirestore('BestsellerRepository: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
      }
      
      // Extract product IDs from the bestseller documents
      List<String> productIds = [];
      
      for (final doc in bestsellersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String?;
        
        if (productId != null && productId.isNotEmpty) {
          productIds.add(productId);
        }
      }
      
      if (!ranked && productIds.length > limit) {
        // Randomize and limit the product IDs
        productIds.shuffle(Random());
        productIds = productIds.take(limit).toList();
        
        LoggingService.logFirestore('BestsellerRepository: Randomized and limited to $limit products');
      }
      
      // Get full product details for these IDs
      final List<Product> products = [];
      
      for (final productId in productIds) {
        final product = await _productService.getProductById(productId);
        if (product != null) {
          products.add(product);
        }
      }
      
      LoggingService.logFirestore('BestsellerRepository: Returning ${products.length} bestseller products');
      return products;
    } catch (e) {
      LoggingService.logError('BestsellerRepository', 'Error getting bestseller products: $e');
      return [];
    }
  }
}
