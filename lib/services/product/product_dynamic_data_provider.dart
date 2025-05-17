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
    final now = DateTime.now();
    final lastTime = _lastEmissionTime[productId];
    
    if (lastTime == null) {
      _lastEmissionTime[productId] = now;
      return false;
    }
    
    final elapsed = now.difference(lastTime);
    if (elapsed < _minimumEmissionInterval) {
      return true; // Throttle - too soon since last emission
    }
    
    _lastEmissionTime[productId] = now;
    return false;
  }

  /// Get a stream of product dynamic data
  /// Fetches real-time price, stock and discount info from RTDB
  /// 
  /// Parameters:
  /// - [categoryGroup]: Category group ID (e.g., "bakeries_biscuits")
  /// - [categoryItem]: Category item ID (e.g., "bakery_snacks")
  /// - [productId]: Product ID
  /// 
  /// Returns a stream that emits ProductDynamicData when the RTDB data changes
  Stream<ProductDynamicData> getProductStream({
    required String categoryGroup,
    required String categoryItem,
    required String productId,
  }) {
    // Create a unique key for this product path
    final String cacheKey = 'products/$categoryGroup/items/$categoryItem/products/$productId';

    // Return cached stream if already created
    if (_activeStreams.containsKey(cacheKey)) {
      return _activeStreams[cacheKey]!;
    }

    // Log stream creation
    LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Creating RTDB stream for $productId at path $cacheKey');
    
    // Create reference to the product in RTDB
    final productRef = _database.ref(cacheKey);
    
    // Create a stream controller
    final streamController = StreamController<ProductDynamicData>.broadcast();
    
    // Listen to RTDB changes
    final subscription = productRef.onValue.listen((event) {
      // Apply rate limiting to prevent excessive emissions
      if (_shouldThrottle(productId)) {
        return; // Skip this emission - too soon since last one
      }
      
      LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Received RTDB event for $productId');
      
      if (event.snapshot.exists && event.snapshot.value != null) {
        // Convert data to Map
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        // Create ProductDynamicData from the RTDB data
        final dynamicData = ProductDynamicData.fromRTDB(data);
        
        LoggingService.logFirestore(
          'PRODUCT_DYNAMIC_PROVIDER: Updated data for $productId - '
          'Price: ${dynamicData.price}, InStock: ${dynamicData.inStock}'
        );
        
        // Add data to stream
        streamController.add(dynamicData);
        
        // Check if we need to combine with discount info
        if (dynamicData.hasDiscount == true) {
          // Product has 'hasDiscount' flag, but discountType and discountValue
          // are stored in the discounts collection, so we need to fetch them
          _checkForDiscount(productId).then((discountData) {
            if (discountData.discountType != null && discountData.discountValue != null) {
              // Apply rate limiting again for combined data
              if (_shouldThrottle(productId)) {
                return; // Skip this emission - too soon since last one
              }
              
              // Create a combined data object with price from product and discount details
              final combinedData = ProductDynamicData(
                price: dynamicData.price,
                quantity: dynamicData.quantity,
                inStock: dynamicData.inStock,
                hasDiscount: true,
                discountType: discountData.discountType,
                discountValue: discountData.discountValue,
                updatedAt: dynamicData.updatedAt,
              );
              
              // Add the combined data to the stream
              streamController.add(combinedData);
            }
          }).catchError((error) {
            // Error fetching discount, use product data only
            LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error checking discount for $productId: $error');
          });
        }
      } else {
        // If data doesn't exist in RTDB under the product path, check discounts
        LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: No RTDB data for $productId at $cacheKey, checking discounts');
        
        // Check for discounts
        _checkForDiscount(productId).then((discountData) {
          if (discountData.hasDiscount == true) {
            LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Found discount for $productId, fetching price...');
            
            // We found a discount, but we need price data
            _searchForProductInCategories(productId).then((productData) {
              // Combine product and discount data
              final combined = productData.merge(discountData);
              
              // Apply rate limiting for the combined result
              if (!_shouldThrottle(productId)) {
                LoggingService.logFirestore(
                  'PRODUCT_DYNAMIC_PROVIDER: Combined product and discount for $productId - '
                  'Price: ${combined.price}, FinalPrice: ${combined.finalPrice}'
                );
                
                streamController.add(combined);
              }
            }).catchError((error) {
              // We could find discount but not price data
              LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error finding price for $productId: $error');
              streamController.add(discountData); // Use discount data only
            });
          } else {
            // No discount found, search for product directly
            _searchForProductInCategories(productId).then((productData) {
              // Apply rate limiting
              if (!_shouldThrottle(productId)) {
                LoggingService.logFirestore(
                  'PRODUCT_DYNAMIC_PROVIDER: Found product data for $productId - '
                  'Price: ${productData.price}, InStock: ${productData.inStock}'
                );
                
                streamController.add(productData);
              }
            }).catchError((error) {
              // Neither product nor discount found
              LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error finding product $productId: $error');
              streamController.add(ProductDynamicData(price: 0, inStock: true));
            });
          }
        }).catchError((error) {
          LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error checking discount for $productId: $error');
          
          // Try to find the product directly as a fallback
          _searchForProductInCategories(productId).then((productData) {
            streamController.add(productData);
          }).catchError((error) {
            // Last resort - emit default data
            streamController.add(ProductDynamicData(price: 0, inStock: true));
          });
        });
      }
    }, onError: (error) {
      LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error in RTDB stream for $productId: $error');
      streamController.add(ProductDynamicData(price: 0, inStock: false));
    });
    
    // Close the stream controller when it's no longer needed
    streamController.onCancel = () {
      subscription.cancel();
      _activeStreams.remove(cacheKey);
      _lastEmissionTime.remove(productId); // Clean up rate limiting data
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
      return _activeStreams[cacheKey]!;
    }

    // Log stream creation
    LoggingService.logFirestore('PRODUCT_DYNAMIC_PROVIDER: Creating ID-only stream for $productId');
    
    // Create a stream controller
    final streamController = StreamController<ProductDynamicData>.broadcast();
    
    // Start by checking for discounts
    _checkForDiscount(productId).then((discountData) {
      // If discount exists, use it while fetching product data
      if (discountData.hasDiscount == true) {
        streamController.add(discountData);
        
        // Also fetch product data for price information
        _searchForProductInCategories(productId).then((productData) {
          // Combine product and discount data
          final combined = productData.merge(discountData);
          
          LoggingService.logFirestore(
            'PRODUCT_DYNAMIC_PROVIDER: Combined product and discount for $productId - '
            'Price: ${combined.price}, FinalPrice: ${combined.finalPrice}'
          );
          
          streamController.add(combined);
        }).catchError((error) {
          // Error fetching product data, but we still have discount
          LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error finding product data for $productId: $error');
        });
      } else {
        // No discount, search for product only
        _searchForProductInCategories(productId).then((productData) {
          LoggingService.logFirestore(
            'PRODUCT_DYNAMIC_PROVIDER: Found product data for $productId - '
            'Price: ${productData.price}, InStock: ${productData.inStock}'
          );
          
          streamController.add(productData);
        }).catchError((error) {
          // Unable to find anything for this product
          LoggingService.logError('PRODUCT_DYNAMIC_PROVIDER', 'Error finding any data for $productId: $error');
          streamController.add(ProductDynamicData(price: 0, inStock: true));
        });
      }
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
    
    // Close resources when stream is closed
    streamController.onCancel = () {
      _activeStreams.remove(cacheKey);
    };
    
    // Create a reference-counted stream to handle multiple listeners
    final stream = streamController.stream;
    
    // Cache the stream for reuse
    _activeStreams[cacheKey] = stream;
    
    return stream;
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
