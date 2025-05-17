import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../services/logging_service.dart';

/// Model class for dynamic product data from Realtime Database
/// Contains price, quantity, stock status, and discount information
class ProductDynamicData {
  final double price;
  final int? quantity;
  final bool inStock;
  final bool? hasDiscount;
  final String? discountType;
  final double? discountValue;
  final String? updatedAt;

  ProductDynamicData({
    required this.price,
    this.quantity,
    required this.inStock,
    this.hasDiscount,
    this.discountType,
    this.discountValue,
    this.updatedAt,
  });

  /// Calculate final price after applying discount
  double get finalPrice {
    if (hasDiscount != true || discountType == null || discountValue == null || discountValue! <= 0) {
      return price;
    }

    if (discountType == 'percentage') {
      final discount = price * (discountValue! / 100);
      return price - discount;
    } else if (discountType == 'flat') {
      return price - discountValue!;
    }
    
    return price;
  }

  /// Create a ProductDynamicData from a Realtime Database snapshot
  static ProductDynamicData fromRTDB(Map<dynamic, dynamic>? data) {
    if (data == null) {
      return ProductDynamicData(
        price: 0, 
        inStock: false,
      );
    }

    // Extract the price, ensuring it's a double
    double price = 0;
    if (data['price'] != null) {
      if (data['price'] is int) {
        price = (data['price'] as int).toDouble();
      } else if (data['price'] is double) {
        price = data['price'] as double;
      } else if (data['price'] is String) {
        price = double.tryParse(data['price'] as String) ?? 0;
      }
    }

    return ProductDynamicData(
      price: price,
      quantity: data['quantity'] is int ? data['quantity'] as int : null,
      inStock: data['inStock'] as bool? ?? false,
      hasDiscount: data['hasDiscount'] as bool? ?? false,
      // discountType and discountValue are not stored with the product in RTDB
      // These will be fetched separately from the discounts collection
      discountType: null,
      discountValue: null,
      updatedAt: data['updatedAt'] is Map ? _parseUpdatedAt(data['updatedAt'] as Map) : null,
    );
  }
  
  /// Parse the updatedAt timestamp from RTDB format
  static String? _parseUpdatedAt(Map timestampData) {
    try {
      if (timestampData.containsKey('seconds')) {
        final seconds = timestampData['seconds'];
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds is int ? seconds : int.parse(seconds.toString())) * 1000
        ).toString();
      }
      return null;
    } catch (e) {
      print('RTDB_PRODUCT_DATA: Error parsing updatedAt: $e');
      return null;
    }
  }

  /// Merge two ProductDynamicData objects, taking non-null values from the other
  ProductDynamicData merge(ProductDynamicData other) {
    return ProductDynamicData(
      price: other.price > 0 ? other.price : this.price,
      quantity: other.quantity ?? this.quantity,
      inStock: other.inStock, // Always take the other's inStock value
      hasDiscount: other.hasDiscount ?? this.hasDiscount,
      discountType: other.discountType ?? this.discountType,
      discountValue: other.discountValue ?? this.discountValue,
      updatedAt: other.updatedAt ?? this.updatedAt,
    );
  }
}

/// Provider service for dynamic product data from Realtime Database
/// Fetches and streams real-time price, stock, and discount data
class ProductDynamicDataProvider {
  // Singleton pattern
  static final ProductDynamicDataProvider _instance = ProductDynamicDataProvider._internal();
  factory ProductDynamicDataProvider() => _instance;
  ProductDynamicDataProvider._internal();

  // Instance of Firebase Realtime Database
  final _database = FirebaseDatabase.instance;

  // Cache for active streams to avoid duplicate listeners
  final Map<String, Stream<ProductDynamicData>> _activeStreams = {};
  
  // Rate limiting - track last emission time by product ID
  final Map<String, DateTime> _lastEmissionTime = {};
  // Minimum time between emissions (500ms)
  final Duration _minimumEmissionInterval = Duration(milliseconds: 500);

  // Known category groups for searching
  final List<String> _knownCategoryGroups = [
    'bakeries_biscuits',
    'beauty_hygiene',
    'dairy_eggs',
    'fruits_vegetables',
    'grocery_kitchen',
    'snacks_drinks'
  ];

  /// Check if we should throttle emission for a product
  bool _shouldThrottle(String productId) {
    // Get the current time
    final now = DateTime.now();
    
    // If no previous emission, allow this one
    if (!_lastEmissionTime.containsKey(productId)) {
      _lastEmissionTime[productId] = now;
      return false;
    }
    
    // Check if it's been long enough since the last emission
    final lastTime = _lastEmissionTime[productId]!;
    final elapsed = now.difference(lastTime);
    
    // If less than minimum interval, throttle
    final shouldThrottle = elapsed < _minimumEmissionInterval;
    
    // For debug logging, only log an incoming update is throttled
    if (shouldThrottle) {
      LoggingService.logFirestore(
        'PRODUCT_DYNAMIC_PROVIDER: Throttling update for $productId (${elapsed.inMilliseconds}ms since last update)'
      );
    } else {
      // Update the last emission time if we're not throttling
      _lastEmissionTime[productId] = now;
    }
    
    return shouldThrottle;
  }

  /// Get a stream of dynamic data for a specific product
  Stream<ProductDynamicData> getProductStream({
    required String categoryGroup,
    required String categoryItem,
    required String productId,
  }) {
    // Create a unique key for this product path
    final String cacheKey = 'products/$categoryGroup/items/$categoryItem/products/$productId';

    // Return cached stream if already created
    if (_activeStreams.containsKey(cacheKey)) {
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Reusing cached stream for $productId');
      return _activeStreams[cacheKey]!;
    }

    // Log stream creation
    LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Creating RTDB stream for $productId at path $cacheKey');
    
    // Create reference to the product in RTDB
    final productRef = _database.ref(cacheKey);
    
    // Create a stream controller
    final streamController = StreamController<ProductDynamicData>.broadcast();
    
    // Initial data fetch - ensures we have data even before the first update
    productRef.get().then((snapshot) {
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final dynamicData = ProductDynamicData.fromRTDB(data);
        
        LoggingService.logFirestore(
          'PRODUCT_DYNAMIC_PROVIDER: Initial data for $productId - '
          'Price: ${dynamicData.price}, InStock: ${dynamicData.inStock}'
        );
        
        // Emit initial data
        streamController.add(dynamicData);
      } else {
        LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: No initial data for $productId');
      }
    }).catchError((error) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error fetching initial data for $productId: $error');
    });
    
    // Listen to RTDB changes with specific event types for better debugging
    final onValueSubscription = productRef.onValue.listen((event) {
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Received onValue event for $productId');

      if (event.snapshot.exists && event.snapshot.value != null) {
        // Only throttle updates, not initial data
        if (_shouldThrottle(productId)) {
          return; // Skip this emission - too soon since last one
        }
        
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final dynamicData = ProductDynamicData.fromRTDB(data);
          
          LoggingService.logFirestore(
            'PRODUCT_DYNAMIC_PROVIDER: Emitting update for $productId - '
            'Price: ${dynamicData.price}, InStock: ${dynamicData.inStock}'
          );
          
          // Add to stream
          streamController.add(dynamicData);
        } catch (e) {
          LoggingService.logError(
            'PRODUCT_DYNAMIC_PROVIDER',
            'Error processing RTDB data for $productId: $e'
          );
        }
      } else {
        LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Empty snapshot for $productId');
      }
    }, onError: (error) {
      LoggingService.logError(
        'PRODUCT_DYNAMIC_PROVIDER',
        'Error in RTDB listener for $productId: $error'
      );
    });
    
    // Also listen specifically for price changes to improve debugging
    productRef.child('price').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        LoggingService.logFirestore(
          'PRODUCT_DYNAMIC_PROVIDER: Price changed for $productId: ${event.snapshot.value}'
        );
      }
    });
    
    // Close resources when stream is closed
    streamController.onCancel = () {
      onValueSubscription.cancel();
      _activeStreams.remove(cacheKey);
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Closed stream for $productId');
    };
    
    // Create a reference-counted stream to handle multiple listeners
    final stream = streamController.stream;
    
    // Cache the stream for reuse
    _activeStreams[cacheKey] = stream;
    
    return stream;
  }

  /// Alternative method to get product dynamic data directly from the product ID
  /// without needing to know its category path
  /// 
  /// This is useful when you just have a product ID reference (like in cart items)
  /// but don't have the full category path information
  Stream<ProductDynamicData> getProductStreamById(String productId) {
    // Create a unique key for this product's ID-only lookup path
    final String cacheKey = 'productById/$productId';

    // Return cached stream if already created
    if (_activeStreams.containsKey(cacheKey)) {
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Reusing cached ID-only stream for $productId');
      return _activeStreams[cacheKey]!;
    }

    // Log stream creation
    LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Creating ID-only stream for $productId');
    
    // Create a stream controller
    final streamController = StreamController<ProductDynamicData>.broadcast();
    
    // Start by checking for discounts
    _checkForDiscount(productId).then((discountData) {
      // Now fetch price and stock information
      _fetchProductPriceAndStock(productId).then((priceData) {
        // Merge discount and price data
        final combinedData = discountData.merge(priceData);
        
        // Add to stream
        streamController.add(combinedData);
        
        // For debugging
        LoggingService.logFirestore(
          'PRODUCT_DYNAMIC_PROVIDER: Initial combined data for $productId - '
          'Price: ${combinedData.price}, InStock: ${combinedData.inStock}, '
          'HasDiscount: ${combinedData.hasDiscount}, Type: ${combinedData.discountType}, '
          'Value: ${combinedData.discountValue}'
        );
        
        // Try to find the indexed path to set up a real-time listener
        _findProductPathById(productId).then((path) {
          if (path != null) {
            LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Found path for $productId: $path');
            
            // Set up a real-time listener for future updates
            final ref = _database.ref(path);
            
            // Listen to changes
            final onValueSubscription = ref.onValue.listen((event) {
              if (event.snapshot.exists && event.snapshot.value != null) {
                // Apply rate limiting to prevent excessive emissions
                if (_shouldThrottle(productId)) {
                  return; // Skip this emission - too soon since last one
                }
                
                try {
                  final data = event.snapshot.value as Map<dynamic, dynamic>;
                  final dynamicData = ProductDynamicData.fromRTDB(data);
                  
                  // Merge with discount data to get final product
                  final updatedData = discountData.merge(dynamicData);
                  
                  LoggingService.logFirestore(
                    'PRODUCT_DYNAMIC_PROVIDER: Real-time update for $productId - '
                    'Price: ${updatedData.price}, InStock: ${updatedData.inStock}'
                  );
                  
                  // Add to stream
                  streamController.add(updatedData);
                } catch (e) {
                  LoggingService.logError(
                    'PRODUCT_DYNAMIC_PROVIDER',
                    'Error processing RTDB update for $productId: $e'
                  );
                }
              }
            }, onError: (error) {
              LoggingService.logError(
                'PRODUCT_DYNAMIC_PROVIDER',
                'Error in RTDB listener for $productId: $error'
              );
            });
            
            // Close resources when stream is closed
            streamController.onCancel = () {
              onValueSubscription.cancel();
              _activeStreams.remove(cacheKey);
              LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Closed ID-only stream for $productId');
            };
          }
        });
      });
    }).catchError((error) {
      // Error checking discount, try product search as fallback
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error checking discount for $productId: $error');
      
      _searchForProductInCategories(productId).then((productData) {
        streamController.add(productData);
      }).catchError((error) {
        // Last resort - emit default data
        LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error finding any data for $productId: $error');
        streamController.add(ProductDynamicData(price: 0, inStock: true));
      });
    });
    
    // Create a reference-counted stream to handle multiple listeners
    final stream = streamController.stream;
    
    // Cache the stream for reuse
    _activeStreams[cacheKey] = stream;
    
    return stream;
  }

  /// Find the RTDB path for a product by its ID
  /// Used for setting up real-time listeners once we know the path
  Future<String?> _findProductPathById(String productId) async {
    try {
      // Check if the product is in the index
      final indexRef = _database.ref('product_index/$productId');
      final indexSnapshot = await indexRef.get();
      
      if (indexSnapshot.exists && indexSnapshot.value != null) {
        return indexSnapshot.value as String;
      }
      
      // Not in index, search categories
      for (final categoryGroup in _knownCategoryGroups) {
        final categoryItemsRef = _database.ref('products/$categoryGroup/items');
        final categoryItemsSnapshot = await categoryItemsRef.get();
        
        if (!categoryItemsSnapshot.exists) continue;
        
        final categoryItems = categoryItemsSnapshot.value as Map<dynamic, dynamic>;
        
        for (final categoryItem in categoryItems.keys) {
          final path = 'products/$categoryGroup/items/$categoryItem/products/$productId';
          final productRef = _database.ref(path);
          final productSnapshot = await productRef.get();
          
          if (productSnapshot.exists) {
            // Add to index for future lookups
            await _database.ref('product_index/$productId').set(path);
            return path;
          }
        }
      }
      
      return null;
    } catch (e) {
      LoggingService.logError(
        'PRODUCT_DYNAMIC_PROVIDER', 
        'Error finding product path for $productId: $e'
      );
      return null;
    }
  }

  /// Check for discount information for a specific product
  Future<ProductDynamicData> _checkForDiscount(String productId) async {
    try {
      // Check discounts node for this product
      final discountRef = _database.ref('discounts/$productId');
      final snapshot = await discountRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Extract discount info - these fields are in the discounts collection
        final discountType = data['discountType'] as String?;
        final discountValue = data['discountValue'] is int 
            ? (data['discountValue'] as int).toDouble() 
            : (data['discountValue'] as double?);
        final isActive = data['active'] as bool? ?? true;
        
        if (isActive && discountType != null && discountValue != null) {
          // We found an active discount
          return ProductDynamicData(
            price: 0, // Price unknown from discount node
            inStock: true, // Assume in stock since we can't tell
            hasDiscount: true,
            discountType: discountType,
            discountValue: discountValue,
          );
        }
      }
      
      // No active discount found
      return ProductDynamicData(
        price: 0,
        inStock: true,
        hasDiscount: false,
      );
    } catch (e) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error checking discount for $productId: $e');
      return ProductDynamicData(price: 0, inStock: true, hasDiscount: false);
    }
  }

  /// Fetch product price and stock information
  Future<ProductDynamicData> _fetchProductPriceAndStock(String productId) async {
    try {
      // Try to find the product in known categories
      final productData = await _searchForProductInCategories(productId);
      
      if (productData.price > 0) {
        // We found price information
        return productData;
      }
      
      // No price information found
      return ProductDynamicData(price: 0, inStock: true);
    } catch (e) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error fetching price for $productId: $e');
      return ProductDynamicData(price: 0, inStock: true);
    }
  }

  /// Search for a product in all categories
  /// This will search through known category groups to find the product
  Future<ProductDynamicData> _searchForProductInCategories(String productId) async {
    try {
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Searching for product $productId in categories');
      
      // First check if we have a product index that maps product IDs to paths
      final indexRef = _database.ref('product_index/$productId');
      final indexSnapshot = await indexRef.get();
      
      if (indexSnapshot.exists && indexSnapshot.value != null) {
        final path = indexSnapshot.value as String;
        
        // Get the product data from the indexed path
        final productRef = _database.ref(path);
        final productSnapshot = await productRef.get();
        
        if (productSnapshot.exists && productSnapshot.value != null) {
          final data = productSnapshot.value as Map<dynamic, dynamic>;
          
          // Create ProductDynamicData from the RTDB data
          final dynamicData = ProductDynamicData.fromRTDB(data);
          
          LoggingService.logFirestore(
            'PRODUCT_DYNAMIC_PROVIDER: Found product $productId at $path - '
            'Price: ${dynamicData.price}, InStock: ${dynamicData.inStock}'
          );
          
          return dynamicData;
        }
      } else {
        // No index, need to search through all category groups
        // This is expensive but necessary when we don't know the path
        
        // Create a list of futures to search all category groups in parallel
        List<Future<ProductDynamicData?>> searchFutures = [];
        
        for (final categoryGroup in _knownCategoryGroups) {
          Future<ProductDynamicData?> searchCategoryGroup = _searchInCategoryGroup(categoryGroup, productId);
          searchFutures.add(searchCategoryGroup);
        }
        
        // Wait for any search to find the product
        final results = await Future.wait(searchFutures);
        
        // Find the first non-null result
        for (final result in results) {
          if (result != null && result.price > 0) {
            return result;
          }
        }
      }
      
      // Fallback default data
      return ProductDynamicData(price: 0, inStock: true);
    } catch (e) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error searching for product $productId: $e');
      return ProductDynamicData(price: 0, inStock: true);
    }
  }
  
  /// Search for a product in a specific category group
  Future<ProductDynamicData?> _searchInCategoryGroup(String categoryGroup, String productId) async {
    try {
      // Get all category items in this group
      final categoryItemsRef = _database.ref('products/$categoryGroup/items');
      final categoryItemsSnapshot = await categoryItemsRef.get();
      
      if (!categoryItemsSnapshot.exists) return null;
      
      final categoryItems = categoryItemsSnapshot.value as Map<dynamic, dynamic>;
      
      // For each category item, check for the product
      for (final categoryItem in categoryItems.keys) {
        final productPath = 'products/$categoryGroup/items/$categoryItem/products/$productId';
        final productRef = _database.ref(productPath);
        final productSnapshot = await productRef.get();
        
        if (productSnapshot.exists && productSnapshot.value != null) {
          final data = productSnapshot.value as Map<dynamic, dynamic>;
          
          // Create ProductDynamicData from the RTDB data
          final dynamicData = ProductDynamicData.fromRTDB(data);
          
          // Also save this path to the product index for faster lookup next time
          try {
            await _database.ref('product_index/$productId').set(productPath);
          } catch (e) {
            // Ignore error saving to index - it's just an optimization
            LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Failed to save to product index: $e');
          }
          
          return dynamicData;
        }
      }
      
      return null;
    } catch (e) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error searching in category group $categoryGroup: $e');
      return null;
    }
  }
  
  /// Clear the stream cache to free up resources
  void clearCache() {
    _activeStreams.clear();
  }
  
  /// Dispose all streams and clear the cache
  void dispose() {
    clearCache();
  }
}
