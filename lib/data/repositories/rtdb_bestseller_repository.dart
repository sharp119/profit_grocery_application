import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../domain/entities/product.dart';
import '../../services/logging_service.dart';
import '../../core/constants/app_constants.dart';

/// RTDB-based repository for bestseller products with complete product information
/// Uses the new simplified database structure for optimal performance
class RTDBBestsellerRepository {
  final FirebaseDatabase _database;
  final FirebaseStorage _storage;
  
  RTDBBestsellerRepository({
    FirebaseDatabase? database,
    FirebaseStorage? storage,
  }) : _database = database ?? FirebaseDatabase.instance,
        _storage = storage ?? FirebaseStorage.instance;
  
  /// Get bestseller products with complete information in minimal network calls
  /// 
  /// Parameters:
  /// - [limit]: Maximum number of products to return (default: 4)
  /// - [ranked]: Whether to maintain bestseller order or randomize (default: false)
  Future<List<Product>> getBestsellerProducts({
    int limit = 4,
    bool ranked = false,
  }) async {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Starting to fetch $limit bestseller products (ranked: $ranked)');
      print('RTDB_BESTSELLER: Starting to fetch $limit bestseller products (ranked: $ranked)');
      
      // Step 1: Get bestseller product IDs from the bestsellers collection
      final bestsellerProductIds = await _getBestsellerProductIds(limit: limit, ranked: ranked);
      
      if (bestsellerProductIds.isEmpty) {
        LoggingService.logFirestore('RTDB_BESTSELLER: No bestseller product IDs found');
        print('RTDB_BESTSELLER: No bestseller product IDs found');
        return [];
      }
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Retrieved ${bestsellerProductIds.length} bestseller IDs: $bestsellerProductIds');
      print('RTDB_BESTSELLER: Retrieved ${bestsellerProductIds.length} bestseller IDs: $bestsellerProductIds');
      
      // Step 2: Get complete product information for these IDs
      final products = await _getProductsInfo(bestsellerProductIds);
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Successfully loaded ${products.length} bestseller products');
      print('RTDB_BESTSELLER: Successfully loaded ${products.length} bestseller products');
      
      return products;
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error getting bestseller products: $e');
      print('RTDB_BESTSELLER ERROR: Failed to get bestseller products - $e');
      return [];
    }
  }
  
  /// Get bestseller product IDs from the bestsellers collection
  Future<List<String>> _getBestsellerProductIds({
    int limit = 4,
    bool ranked = false,
  }) async {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Fetching bestseller IDs from RTDB');
      print('RTDB_BESTSELLER: Fetching bestseller IDs from RTDB');
      
      // Get the bestsellers list from RTDB
      final DatabaseReference bestsellerRef = _database.ref('bestsellers');
      final DataSnapshot snapshot = await bestsellerRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        LoggingService.logFirestore('RTDB_BESTSELLER: No bestsellers data found in RTDB');
        print('RTDB_BESTSELLER: No bestsellers data found in RTDB');
        return [];
      }
      
      // Parse the bestsellers data
      List<String> productIds = [];
      final data = snapshot.value;
      
      if (data is Map) {
        // Handle object structure {0: "productId1", 1: "productId2", ...}
        final Map<dynamic, dynamic> bestsellerMap = data;
        
        // Sort by index to maintain order
        final sortedKeys = bestsellerMap.keys.toList()..sort((a, b) {
          final aInt = int.tryParse(a.toString()) ?? 0;
          final bInt = int.tryParse(b.toString()) ?? 0;
          return aInt.compareTo(bInt);
        });
        
        for (final key in sortedKeys) {
          final productId = bestsellerMap[key]?.toString();
          if (productId != null && productId.isNotEmpty) {
            productIds.add(productId);
          }
        }
      } else if (data is List) {
        // Handle array structure ["productId1", "productId2", ...]
        for (final item in data) {
          final productId = item?.toString();
          if (productId != null && productId.isNotEmpty) {
            productIds.add(productId);
          }
        }
      }
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Found ${productIds.length} bestseller product IDs');
      print('RTDB_BESTSELLER: Found ${productIds.length} bestseller product IDs');
      
      // Apply limit and ranking logic
      if (!ranked && productIds.length > limit) {
        // Randomize the selection
        productIds.shuffle(Random());
        productIds = productIds.take(limit).toList();
        LoggingService.logFirestore('RTDB_BESTSELLER: Randomized and limited to $limit products');
        print('RTDB_BESTSELLER: Randomized and limited to $limit products');
      } else if (ranked) {
        // Keep original order but limit
        productIds = productIds.take(limit).toList();
        LoggingService.logFirestore('RTDB_BESTSELLER: Kept ranking order and limited to $limit products');
        print('RTDB_BESTSELLER: Kept ranking order and limited to $limit products');
      }
      
      return productIds;
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error getting bestseller product IDs: $e');
      print('RTDB_BESTSELLER ERROR: Failed to get bestseller IDs - $e');
      return [];
    }
  }
  
  /// Get complete product information for the given product IDs
  Future<List<Product>> _getProductsInfo(List<String> productIds) async {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Fetching complete product info for ${productIds.length} products');
      print('RTDB_BESTSELLER: Fetching complete product info for ${productIds.length} products');
      
      List<Product> products = [];
      
      // Get the dynamic_product_info reference
      final DatabaseReference productInfoRef = _database.ref('dynamic_product_info');
      
      for (final productId in productIds) {
        try {
          LoggingService.logFirestore('RTDB_BESTSELLER: Fetching data for product: $productId');
          print('RTDB_BESTSELLER: Fetching data for product: $productId');
          
          // Get product data from dynamic_product_info
          final DataSnapshot productSnapshot = await productInfoRef.child(productId).get();
          
          if (!productSnapshot.exists || productSnapshot.value == null) {
            LoggingService.logFirestore('RTDB_BESTSELLER: Product data not found for: $productId');
            print('RTDB_BESTSELLER: ⚠️ Product data not found for: $productId');
            continue;
          }
          
          final Map<dynamic, dynamic> productData = productSnapshot.value as Map<dynamic, dynamic>;
          
          // Parse the product data according to your RTDB structure
          final product = _parseProductFromRTDB(productId, productData);
          
          if (product != null) {
            products.add(product);
            LoggingService.logFirestore('RTDB_BESTSELLER: Successfully parsed product: ${product.name}');
            print('RTDB_BESTSELLER: Successfully parsed product: ${product.name}');
          }
          
        } catch (e) {
          LoggingService.logError('RTDB_BESTSELLER', 'Error getting product $productId: $e');
          print('RTDB_BESTSELLER ERROR: Failed to get product $productId - $e');
          continue;
        }
      }
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Successfully fetched ${products.length} complete products');
      print('RTDB_BESTSELLER: Successfully fetched ${products.length} complete products');
      
      return products;
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error getting products info: $e');
      print('RTDB_BESTSELLER ERROR: Failed to get products info - $e');
      return [];
    }
  }
  
  /// Convert Firebase Storage path to download URL
  Future<String> _getImageDownloadUrl(String path) async {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Converting path to download URL: $path');
      print('RTDB_BESTSELLER: Converting path to download URL: $path');
      
      // Check if it's already a valid HTTP URL
      if (path.startsWith('http://') || path.startsWith('https://')) {
        LoggingService.logFirestore('RTDB_BESTSELLER: Path is already a valid URL: $path');
        print('RTDB_BESTSELLER: Path is already a valid URL: $path');
        return path;
      }
      
      Reference ref;
      
      // Handle different path formats
      if (path.startsWith('gs://')) {
        // Full gs:// URL
        ref = _storage.refFromURL(path);
      } else {
        // Relative path - construct full path
        // Remove leading slash if present
        String cleanPath = path.startsWith('/') ? path.substring(1) : path;
        ref = _storage.ref(cleanPath);
      }
      
      final downloadUrl = await ref.getDownloadURL();
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Successfully converted to download URL: $downloadUrl');
      print('RTDB_BESTSELLER: Successfully converted to download URL: $downloadUrl');
      
      return downloadUrl;
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error converting path to download URL ($path): $e');
      print('RTDB_BESTSELLER ERROR: Failed to convert path to download URL ($path) - $e');
      
      // Return empty string if conversion fails
      return '';
    }
  }
  
  /// Parse product data from RTDB structure to Product entity
  Product? _parseProductFromRTDB(String productId, Map<dynamic, dynamic> data) {
    try {
      // Extract basic product information
      final String? name = data['name']?.toString();
      final String? brand = data['brand']?.toString();
      final String? weight = data['weight']?.toString();
      final String? path = data['path']?.toString();
      final String? imagePath = data['imagePath']?.toString(); // Use imagePath field
      final bool inStock = data['inStock'] as bool? ?? true;
      final int quantity = data['quantity'] as int? ?? 0;
      
      // Extract pricing information
      final double mrp = _parseDouble(data['mrp']) ?? 0.0;
      
      // Extract discount information
      final Map<dynamic, dynamic>? discountData = data['discount'] as Map<dynamic, dynamic>?;
      final bool hasDiscount = data['hasDiscount'] as bool? ?? false;
      
      double finalPrice = mrp;
      String? discountType;
      double? discountValue;
      
      if (hasDiscount && discountData != null) {
        discountType = discountData['type']?.toString();
        discountValue = _parseDouble(discountData['value']);
        final bool isActive = discountData['isActive'] as bool? ?? false;
        
        // Check if discount is currently active
        if (isActive && discountType != null && discountValue != null) {
          final int? startTime = discountData['start'] as int?;
          final int? endTime = discountData['end'] as int?;
          final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Convert to seconds
          
          bool isInTimeRange = true;
          if (startTime != null && endTime != null) {
            isInTimeRange = currentTime >= startTime && currentTime <= endTime;
          }
          
          if (isInTimeRange) {
            // Apply discount
            if (discountType.toLowerCase() == 'percentage') {
              finalPrice = mrp * (1 - (discountValue / 100));
            } else if (discountType.toLowerCase() == 'flat') {
              finalPrice = mrp - discountValue;
            }
            
            // Ensure price doesn't go below 0
            if (finalPrice < 0) finalPrice = 0;
            
            LoggingService.logFirestore(
              'RTDB_BESTSELLER: Applied discount to $name - Type: $discountType, Value: $discountValue, '
              'MRP: $mrp, Final: $finalPrice'
            );
            print(
              'RTDB_BESTSELLER: Applied discount to $name - Type: $discountType, Value: $discountValue, '
              'MRP: $mrp, Final: $finalPrice'
            );
          } else {
            LoggingService.logFirestore('RTDB_BESTSELLER: Discount expired for $name');
            print('RTDB_BESTSELLER: Discount expired for $name');
          }
        }
      }
      
      // Extract background color
      final int? colorValue = data['itemBackgroundColor'] as int?;
      Color? itemBackgroundColor;
      if (colorValue != null) {
        itemBackgroundColor = Color(colorValue);
      }
      
      // Use imagePath directly - it's already a full Firebase Storage URL
      String imageUrl = imagePath ?? '';
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Using imagePath for $name: $imageUrl');
      print('RTDB_BESTSELLER: Using imagePath for $name: $imageUrl');
      
      if (name == null) {
        LoggingService.logFirestore('RTDB_BESTSELLER: Missing name for product $productId');
        print('RTDB_BESTSELLER: ⚠️ Missing name for product $productId');
        return null;
      }
      
      // Create Product entity
      final product = Product(
        id: productId,
        name: name,
        description: '$brand ${weight ?? ''}'.trim(),
        price: finalPrice,
        mrp: mrp != finalPrice ? mrp : null, // Only set MRP if different from final price
        image: imageUrl,
        categoryId: '', // You might want to extract this from path
        categoryName: path?.split('/').first ?? '',
        subcategoryId: '',
        tags: [brand, weight].where((tag) => tag != null && tag.isNotEmpty).cast<String>().toList(),
        weight: weight,
        brand: brand,
        inStock: inStock && quantity > 0,
        // Custom properties for RTDB-specific data
        customProperties: {
          'itemBackgroundColor': itemBackgroundColor,
          'hasDiscount': hasDiscount,
          'discountType': discountType,
          'discountValue': discountValue,
          'quantity': quantity,
          'categoryPath': path, // Keep category path for reference
          'imagePath': imagePath, // Keep original imagePath for debugging
        },
      );
      
      LoggingService.logFirestore(
        'RTDB_BESTSELLER: Parsed product - Name: $name, Brand: $brand, Weight: $weight, '
        'MRP: $mrp, Final Price: $finalPrice, In Stock: ${product.inStock}, Image URL: $imageUrl'
      );
      print(
        'RTDB_BESTSELLER: Parsed product - Name: $name, Brand: $brand, Weight: $weight, '
        'MRP: $mrp, Final Price: $finalPrice, In Stock: ${product.inStock}, Image URL: $imageUrl'
      );
      
      return product;
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error parsing product $productId: $e');
      print('RTDB_BESTSELLER ERROR: Failed to parse product $productId - $e');
      return null;
    }
  }
  
  /// Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Get real-time stream of bestseller products
  Stream<List<Product>> getBestsellerProductsStream({
    int limit = 4,
    bool ranked = false,
  }) {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Setting up real-time stream for bestseller products');
      print('RTDB_BESTSELLER: Setting up real-time stream for bestseller products');
      
      // Listen to changes in dynamic_product_info for real-time product updates
      return _database.ref('dynamic_product_info').onValue.asyncMap((productEvent) async {
        LoggingService.logFirestore('RTDB_BESTSELLER: Product data changed, refreshing bestsellers');
        print('RTDB_BESTSELLER: Product data changed, refreshing bestsellers');
        return await getBestsellerProducts(limit: limit, ranked: ranked);
      });
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error setting up real-time stream: $e');
      print('RTDB_BESTSELLER ERROR: Failed to setup stream - $e');
      return Stream.value([]);
    }
  }
  
  /// Get real-time stream for specific bestseller product IDs (more efficient)
  Stream<List<Product>> getBestsellerProductsStreamOptimized({
    int limit = 4,
    bool ranked = false,
  }) async* {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Setting up optimized real-time stream');
      print('RTDB_BESTSELLER: Setting up optimized real-time stream');
      
      // First, get the current bestseller product IDs
      final productIds = await _getBestsellerProductIds(limit: limit, ranked: ranked);

      if (productIds.isEmpty) {
        LoggingService.logFirestore('RTDB_BESTSELLER: No product IDs found for stream');
        print('RTDB_BESTSELLER: No product IDs found for stream');
        yield [];
        return;
      }
      
      LoggingService.logFirestore('RTDB_BESTSELLER: Listening to changes for products: $productIds');
      print('RTDB_BESTSELLER: Listening to changes for products: $productIds');
      
      // Yield initial data
      final initialProducts = await _getProductsInfo(productIds);
      yield initialProducts;
      
      // Listen to changes in the entire dynamic_product_info tree
      // This is more reliable than individual product listeners
      await for (final event in _database.ref('dynamic_product_info').onValue) {
        LoggingService.logFirestore('RTDB_BESTSELLER: Detected change in product data');
        print('RTDB_BESTSELLER: Detected change in product data');
        
        try {
          // Fetch updated products
          final updatedProducts = await _getProductsInfo(productIds);
          
          LoggingService.logFirestore('RTDB_BESTSELLER: Yielding ${updatedProducts.length} updated products');
          print('RTDB_BESTSELLER: Yielding ${updatedProducts.length} updated products');
          
          yield updatedProducts;
        } catch (e) {
          LoggingService.logError('RTDB_BESTSELLER', 'Error fetching updated products: $e');
          print('RTDB_BESTSELLER ERROR: Error fetching updated products - $e');
          // Don't yield on error, keep the last successful state
        }
      }
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error in optimized stream: $e');
      print('RTDB_BESTSELLER ERROR: Failed in optimized stream - $e');
      yield [];
    }
  }
  
  /// Refresh bestseller data manually (useful for pull-to-refresh)
  Future<void> refreshBestsellerData() async {
    try {
      LoggingService.logFirestore('RTDB_BESTSELLER: Manual refresh triggered');
      print('RTDB_BESTSELLER: Manual refresh triggered');
      
      // This will trigger a refresh in any active streams
      // by updating a timestamp or triggering a database event
      await _database.ref('.info/connected').once();
      
    } catch (e) {
      LoggingService.logError('RTDB_BESTSELLER', 'Error during manual refresh: $e');
      print('RTDB_BESTSELLER ERROR: Manual refresh failed - $e');
    }
  }
}
