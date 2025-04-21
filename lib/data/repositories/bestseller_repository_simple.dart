import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/logging_service.dart';

/// Simplified repository for bestseller product operations.
/// Only fetches product IDs without loading full product details.
class BestsellerRepositorySimple {
  final FirebaseFirestore _firestore;
  
  BestsellerRepositorySimple({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get bestseller product IDs only
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of products to return (default: 6)
  /// - [ranked]: Whether to sort products by rank or randomize (default: true)
  Future<List<String>> getBestsellerProductIds({
    int limit = 12,
    bool ranked = false,
  }) async {
    try {
      LoggingService.logFirestore('BESTSELLER_SIMPLE: Getting bestseller product IDs (limit: $limit, ranked: $ranked)');
      print('BESTSELLER_SIMPLE: Getting bestseller product IDs (limit: $limit, ranked: $ranked)');
      
      // Get all bestsellers from the bestsellers collection
      QuerySnapshot bestsellersSnapshot;
      
      if (ranked) {
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .orderBy('rank')
            .limit(limit)
            .get();
        
        LoggingService.logFirestore('BESTSELLER_SIMPLE: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
        print('BESTSELLER_SIMPLE: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
      } else {
        bestsellersSnapshot = await _firestore.collection('bestsellers').get();
        
        LoggingService.logFirestore('BESTSELLER_SIMPLE: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
        print('BESTSELLER_SIMPLE: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
      }
      
      // Extract product IDs from the bestseller documents
      List<String> productIds = [];
      
      for (final doc in bestsellersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String?;
        final rank = data['rank'] as int? ?? 999;
        
        if (productId != null && productId.isNotEmpty) {
          productIds.add(productId);
          LoggingService.logFirestore('BESTSELLER_SIMPLE: Added product ID: $productId, Rank: $rank');
          print('BESTSELLER_SIMPLE: Added product ID: $productId, Rank: $rank');
        }
      }
      
      if (!ranked && productIds.length > limit) {
        productIds.shuffle(Random());
        productIds = productIds.take(limit).toList();
        
        LoggingService.logFirestore('BESTSELLER_SIMPLE: Randomized and limited to $limit product IDs');
        print('BESTSELLER_SIMPLE: Randomized and limited to $limit product IDs');
      }
      
      LoggingService.logFirestore('BESTSELLER_SIMPLE: Returning ${productIds.length} bestseller product IDs');
      print('BESTSELLER_SIMPLE: Returning ${productIds.length} bestseller product IDs');
      return productIds;
    } catch (e) {
      LoggingService.logError('BESTSELLER_SIMPLE', 'Error getting bestseller product IDs: $e');
      print('BESTSELLER_SIMPLE ERROR: Failed to get bestseller product IDs - $e');
      return [];
    }
  }
}