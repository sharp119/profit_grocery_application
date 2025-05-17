import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../domain/entities/bestseller_item.dart';
import '../../services/logging_service.dart';
import 'package:get_it/get_it.dart';

/// Simplified repository for bestseller product operations.
/// Gets bestseller items with their discount information.
class BestsellerRepositorySimple {
  final FirebaseFirestore _firestore;
  
  // Cache mechanism to avoid repeated fetches
  final Map<String, List<BestsellerItem>> _bestsellersCache = {};
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = Duration(minutes: 15); // Cache for 15 minutes
  
  BestsellerRepositorySimple({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get bestseller items with discount information
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of products to return (default: 12)
  /// - [ranked]: Whether to sort products by rank or randomize (default: false)
  Future<List<BestsellerItem>> getBestsellerItems({
    int limit = 2,
    bool ranked = false,
  }) async {
    try {
      // Create a cache key
      final cacheKey = 'bestsellers_${ranked ? 'ranked' : 'random'}_$limit';
      
      // Check if we have a valid cache
      if (_bestsellersCache.containsKey(cacheKey) && 
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        LoggingService.logFirestore('BESTSELLER_REPO: Using cached bestseller items');
        print('BESTSELLER_REPO: Using cached bestseller items (${_bestsellersCache[cacheKey]!.length} items)');
        return _bestsellersCache[cacheKey]!;
      }
      
      LoggingService.logFirestore('BESTSELLER_REPO: Cache miss - fetching bestseller items from Firestore');
      print('BESTSELLER_REPO: Getting bestseller items (limit: $limit, ranked: $ranked)');
      
      // Get all bestsellers from the bestsellers collection
      QuerySnapshot bestsellersSnapshot;
      final Stopwatch stopwatch = Stopwatch()..start();
      
      if (ranked) {
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .orderBy('rank')
            .limit(limit)
            .get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} ranked bestsellers');
      } else {
        // Only fetch the number of items we need plus some buffer for efficiency
        // No need to fetch the entire collection if we're going to randomize and limit
        final fetchLimit = limit * 2; // Fetch twice the needed amount for better randomization
        bestsellersSnapshot = await _firestore.collection('bestsellers')
            .limit(fetchLimit)
            .get();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
        print('BESTSELLER_REPO: Retrieved ${bestsellersSnapshot.docs.length} bestsellers for randomization');
      }
      
      stopwatch.stop();
      print('BESTSELLER_REPO: Time to fetch bestsellers: ${stopwatch.elapsedMilliseconds}ms');
      
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
      }
      
      // Check for active discounts from the discounts collection (only if we have a reasonable number of items)
      if (bestsellerItems.length <= 20) {  // Only process discounts if we have a reasonable number
        await _checkAndApplyActiveDiscounts(bestsellerItems);
      }
      
      if (!ranked && bestsellerItems.length > limit) {
        bestsellerItems.shuffle(Random());
        bestsellerItems = bestsellerItems.take(limit).toList();
        
        LoggingService.logFirestore('BESTSELLER_REPO: Randomized and limited to $limit bestseller items');
        print('BESTSELLER_REPO: Randomized and limited to $limit bestseller items');
      }
      
      // Store in cache
      _bestsellersCache[cacheKey] = bestsellerItems;
      _lastFetchTime = DateTime.now();
      
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
      
      // Get all product IDs that don't have discounts yet
      final productIdsWithoutDiscount = items
          .where((item) => !item.hasSpecialDiscount)
          .map((item) => item.productId)
          .toList();
      
      if (productIdsWithoutDiscount.isEmpty) return;
      
      // Use batch query if possible to improve performance
      try {
        // Process in batches of 10 (Firestore limitation for 'whereIn')
        for (int i = 0; i < productIdsWithoutDiscount.length; i += 10) {
          final batchIds = productIdsWithoutDiscount.sublist(
              i, min(i + 10, productIdsWithoutDiscount.length));
          
          // Batch query for active discounts
          final discountsSnapshot = await _firestore.collection('discounts')
              .where(FieldPath.documentId, whereIn: batchIds)
              .where('active', isEqualTo: true)
              .get();
          
          for (final doc in discountsSnapshot.docs) {
            final productId = doc.id;
            final discountData = doc.data();
            
            // Find the corresponding bestseller item
            final item = items.firstWhere(
                (item) => item.productId == productId, 
                orElse: () => null as BestsellerItem); // force non-null check
            
            if (item == null) continue;
            
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
            if (isInTimeRange) {
              final discountType = discountData['discountType'] as String?;
              final discountValue = (discountData['discountValue'] is int)
                ? (discountData['discountValue'] as int).toDouble()
                : discountData['discountValue'] as double?;
              
              // Update the bestseller item with discount information
              if (discountType != null && discountValue != null) {
                item.discountType = discountType;
                item.discountValue = discountValue;
              }
            }
          }
        }
      } catch (e) {
        print('BESTSELLER_REPO: Error in batch discount check: $e');
        // Fall back to individual checks on error
        _checkDiscountsIndividually(items, now);
      }
    } catch (e) {
      print('BESTSELLER_REPO: Error checking active discounts: $e');
    }
  }
  
  /// Fallback method to check discounts individually if batch processing fails
  Future<void> _checkDiscountsIndividually(List<BestsellerItem> items, int now) async {
    try {
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
              }
            }
          }
        } catch (e) {
          print('BESTSELLER_REPO: Error checking discount for ${item.productId}: $e');
        }
      }
    } catch (e) {
      print('BESTSELLER_REPO: Error in individual discount checks: $e');
    }
  }
  
  /// Clear the bestsellers cache to force refresh
  void clearCache() {
    _bestsellersCache.clear();
    _lastFetchTime = null;
    print('BESTSELLER_REPO: Cache cleared');
  }
  
  /// Legacy method to maintain backward compatibility
  /// Returns just the product IDs without discount information
  Future<List<String>> getBestsellerProductIds({
    int limit = 2,
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