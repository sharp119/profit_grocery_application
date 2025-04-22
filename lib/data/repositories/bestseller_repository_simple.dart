import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../domain/entities/bestseller_item.dart';
import '../../services/logging_service.dart';

/// Simplified repository for bestseller product operations.
/// Gets bestseller items with their discount information.
class BestsellerRepositorySimple {
  final FirebaseFirestore _firestore;
  
  BestsellerRepositorySimple({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get bestseller items with discount information
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of products to return (default: 12)
  /// - [ranked]: Whether to sort products by rank or randomize (default: false)
  Future<List<BestsellerItem>> getBestsellerItems({
    int limit = 12,
    bool ranked = false,
  }) async {
    try {
      LoggingService.logFirestore('BESTSELLER_REPO: Getting bestseller items (limit: $limit, ranked: $ranked)');
      print('BESTSELLER_REPO: Getting bestseller items (limit: $limit, ranked: $ranked)');
      
      // Get all bestsellers from the bestsellers collection
      QuerySnapshot bestsellersSnapshot;
      
      if (ranked) {
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .orderBy('rank')
            .limit(limit)
            .get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
      } else {
        bestsellersSnapshot = await _firestore.collection('bestsellers').get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
      }
      
      // Extract BestsellerItem objects from the bestseller documents
      List<BestsellerItem> bestsellerItems = [];
      
      for (final doc in bestsellersSnapshot.docs) {
        // Get document ID as the product ID
        final productId = doc.id;
        
        // Extract data from the document
        final data = doc.data() as Map<String, dynamic>;
        final rank = data['rank'] as int? ?? 999;
        final discountType = data['discountType'] as String?;
        final discountValue = (data['discountValue'] is int) 
          ? (data['discountValue'] as int).toDouble() 
          : data['discountValue'] as double?;
        
        // Create bestseller item
        final item = BestsellerItem(
          productId: productId,
          rank: rank,
          discountType: discountType,
          discountValue: discountValue,
        );
        
        bestsellerItems.add(item);
        
        LoggingService.logFirestore(
          'BESTSELLER_REPO: Doc ${doc.id} => Product ID: $productId, '
          'Rank: $rank, Discount: ${discountType ?? 'None'} ${discountValue ?? '0'}, '
          'Ref: ${doc.reference.path}'
        );
        
        print('BESTSELLER_REPO: Doc ${doc.id} => Product ID: $productId, '
            'Rank: $rank, Discount: ${discountType ?? 'None'} ${discountValue ?? '0'}, '
            'Ref: ${doc.reference.path}');
      }
      
      // Check for active discounts from the discounts collection
      // This will supplement the bestseller items with any active discounts
      await _checkAndApplyActiveDiscounts(bestsellerItems);
      
      if (!ranked && bestsellerItems.length > limit) {
        bestsellerItems.shuffle(Random());
        bestsellerItems = bestsellerItems.take(limit).toList();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Randomized and limited to $limit bestseller items');
        print('BESTSELLER_REPO: Randomized and limited to $limit bestseller items');
      }
      
      LoggingService.logFirestore('BESTSELLER_REPO: Returning ${bestsellerItems.length} bestseller items');
      print('BESTSELLER_REPO: Returning ${bestsellerItems.length} bestseller items');
      return bestsellerItems;
    } catch (e) {
      LoggingService.logError('BESTSELLER_REPO', 'Error getting bestseller items: $e');
      print('BESTSELLER_REPO ERROR: Failed to get bestseller items - $e');
      return [];
    }
  }
  
  /// Check the discounts collection for active discounts and apply them to bestseller items
  /// if they don't already have a discount
  Future<void> _checkAndApplyActiveDiscounts(List<BestsellerItem> items) async {
    try {
      // Get current timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // For each bestseller item
      for (final item in items) {
        // Skip if bestseller already has a discount
        if (item.hasSpecialDiscount) continue;
        
        try {
          // Check discounts collection for active discount on this product
          final discountDoc = await _firestore.collection('discounts').doc(item.productId).get();
          
          if (discountDoc.exists) {
            final discountData = discountDoc.data() as Map<String, dynamic>;
            
            // Check if discount is active
            final isActive = discountData['active'] as bool? ?? false;
            
            // Check timestamp validity if they exist
            bool isInTimeRange = true;
            
            if (discountData.containsKey('startTimestamp') && discountData.containsKey('endTimestamp')) {
              // Extract timestamps - handle both Timestamp objects and String representations
              Timestamp? startTimestamp;
              Timestamp? endTimestamp;
              
              if (discountData['startTimestamp'] is Timestamp) {
                startTimestamp = discountData['startTimestamp'] as Timestamp;
              } else if (discountData['startTimestamp'] is String) {
                // Parse string to DateTime then to Timestamp
                try {
                  final startDate = DateTime.parse(discountData['startTimestamp'] as String);
                  startTimestamp = Timestamp.fromDate(startDate);
                } catch (e) {
                  print('BESTSELLER_REPO: Error parsing startTimestamp: $e');
                }
              }
              
              if (discountData['endTimestamp'] is Timestamp) {
                endTimestamp = discountData['endTimestamp'] as Timestamp;
              } else if (discountData['endTimestamp'] is String) {
                // Parse string to DateTime then to Timestamp
                try {
                  final endDate = DateTime.parse(discountData['endTimestamp'] as String);
                  endTimestamp = Timestamp.fromDate(endDate);
                } catch (e) {
                  print('BESTSELLER_REPO: Error parsing endTimestamp: $e');
                }
              }
              
              // Check if current time is within range
              if (startTimestamp != null && endTimestamp != null) {
                final startMs = startTimestamp.millisecondsSinceEpoch;
                final endMs = endTimestamp.millisecondsSinceEpoch;
                isInTimeRange = now >= startMs && now <= endMs;
              }
            }
            
            // Apply discount if active and in time range
            if (isActive && isInTimeRange) {
              final discountType = discountData['discountType'] as String?;
              final discountValue = (discountData['discountValue'] is int)
                ? (discountData['discountValue'] as int).toDouble()
                : discountData['discountValue'] as double?;
              
              // Update the bestseller item with discount information
              if (discountType != null && discountValue != null) {
                item.discountType = discountType;
                item.discountValue = discountValue;
                
                LoggingService.logFirestore(
                  'BESTSELLER_REPO: Applied active discount to ${item.productId}: '
                  'Type: $discountType, Value: $discountValue'
                );
                print('BESTSELLER_REPO: Applied active discount to ${item.productId}: '
                    'Type: $discountType, Value: $discountValue');
              }
            }
          }
        } catch (e) {
          print('BESTSELLER_REPO: Error checking discount for ${item.productId}: $e');
          // Continue with next item
        }
      }
    } catch (e) {
      print('BESTSELLER_REPO: Error checking active discounts: $e');
    }
  }
  
  /// Legacy method to maintain backward compatibility
  /// Returns just the product IDs without discount information
  Future<List<String>> getBestsellerProductIds({
    int limit = 12,
    bool ranked = false,
  }) async {
    try {
      final bestsellerItems = await getBestsellerItems(
        limit: limit,
        ranked: ranked,
      );
      
      return bestsellerItems.map((item) => item.productId).toList();
    } catch (e) {
      LoggingService.logError('BESTSELLER_REPO', 'Error in legacy getBestsellerProductIds: $e');
      print('BESTSELLER_REPO ERROR: Failed in legacy getBestsellerProductIds - $e');
      return [];
    }
  }
}