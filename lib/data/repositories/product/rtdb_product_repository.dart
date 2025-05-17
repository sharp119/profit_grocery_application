import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';
import '../../../services/logging_service.dart';

/// Product repository that combines Firestore and Realtime Database
/// Uses Firestore for static product data and RTDB for real-time updates (price, stock, discounts)
/// Optimized for real-time updates and smooth UI experience
class RTDBProductRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Cache of active database references to avoid duplicate listeners
  final Map<String, DatabaseReference> _databaseRefs = {};
  
  // Map of active listeners by category ID
  final Map<String, StreamSubscription<DatabaseEvent>> _listeners = {};
  
  // Cache of products by category to avoid unnecessary state updates
  final Map<String, List<ProductModel>> _productCache = <String, List<ProductModel>>{};
  
  // Throttling variables
  DateTime _lastUpdateTime = DateTime.now();
  static const _updateThrottleMs = 300; // Minimum time between UI updates
  
  RTDBProductRepository() {
    _initDatabase();
  }
  
  /// Initialize the database with persistence settings
  void _initDatabase() {
    try {
      // Configure database for offline support - these methods return void, not Future
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10485760); // 10MB cache
      
      if (kDebugMode) {
        print('RTDB: Firebase Realtime Database initialized with persistence');
      }
    } catch (e) {
      // Persistence might already be enabled, which would throw an error
      if (kDebugMode) {
        print('RTDB: Firebase persistence already initialized: $e');
      }
    }
  }

  /// Get a stream of products for a specific category
  /// This is the primary method to use for real-time updates in the UI
  /// Merges static data from Firestore with real-time data from RTDB
  Stream<List<ProductModel>> getProductsStream(String categoryGroup, String categoryItem) {
    final rtdbPath = 'products/$categoryGroup/items/$categoryItem/products';
    final firestorePath = 'products/$categoryGroup/items/$categoryItem/products';
    
    // Create a StreamController to emit product lists
    final controller = StreamController<List<ProductModel>>.broadcast(
      onCancel: () {
        // Clean up resources when the stream is no longer being listened to
        removeListener(categoryItem);
      }
    );
    
    // Use the cached reference if available, or create a new one
    final dbRef = _databaseRefs[rtdbPath] ?? _database.ref().child(rtdbPath);
    _databaseRefs[rtdbPath] = dbRef;
    
    // Enable persistence for this specific path - keepSynced returns void, not Future
    try {
      dbRef.keepSynced(true);
      
      if (kDebugMode) {
        print('RTDB: Enabled persistence for path: $rtdbPath');
      }
    } catch (e) {
      // Ignore errors here - it's not critical if this fails
      if (kDebugMode) {
        print('RTDB: Could not enable persistence for path: $rtdbPath - $e');
      }
    }
    
    // First, get the static product data from Firestore (once)
    _loadFirestoreProductData(categoryGroup, categoryItem).then((firestoreProducts) {
      // Create a map for quick lookup
      final productMap = {for (var p in firestoreProducts) p.id: p};
      
      // Now set up the real-time listener for RTDB updates
      final listener = dbRef.onValue.listen((event) {
        try {
          // Throttle updates to prevent excessive rebuilds
          final now = DateTime.now();
          if (now.difference(_lastUpdateTime).inMilliseconds < _updateThrottleMs) {
            return; // Skip this update if too soon after the last one
          }
          _lastUpdateTime = now;
          
          final List<ProductModel> mergedProducts = [];
          
          if (event.snapshot.exists) {
            // Parse the RTDB data
            final data = event.snapshot.value as Map<dynamic, dynamic>?;
            if (data != null) {
              data.forEach((key, value) {
                try {
                  final productId = key.toString();
                  
                  // Get static data from Firestore (if available)
                  final firestoreProduct = productMap[productId];
                  
                  // If we have the product in Firestore
                  if (firestoreProduct != null) {
                    // Extract real-time data from RTDB
                    Map<String, dynamic> rtdbData = {};
                    if (value is Map<dynamic, dynamic>) {
                      rtdbData = Map<String, dynamic>.from(
                        value.map((k, v) => MapEntry(k.toString(), v))
                      );
                    }
                    
                    // Create merged product with priority to RTDB for dynamic fields
                    double price = firestoreProduct.price;
                    if (rtdbData.containsKey('price') && rtdbData['price'] != null) {
                      if (rtdbData['price'] is int) {
                        price = (rtdbData['price'] as int).toDouble();
                      } else if (rtdbData['price'] is double) {
                        price = rtdbData['price'] as double;
                      } else if (rtdbData['price'] is num) {
                        price = (rtdbData['price'] as num).toDouble();
                      }
                    }
                    
                    double? mrp = firestoreProduct.mrp;
                    if (rtdbData.containsKey('mrp') && rtdbData['mrp'] != null) {
                      if (rtdbData['mrp'] is int) {
                        mrp = (rtdbData['mrp'] as int).toDouble();
                      } else if (rtdbData['mrp'] is double) {
                        mrp = rtdbData['mrp'] as double;
                      } else if (rtdbData['mrp'] is num) {
                        mrp = (rtdbData['mrp'] as num).toDouble();
                      }
                    }
                    
                    final bool inStock = rtdbData.containsKey('inStock') ? 
                        (rtdbData['inStock'] as bool? ?? firestoreProduct.inStock) : 
                        firestoreProduct.inStock;
                        
                    final bool hasDiscount = rtdbData.containsKey('hasDiscount') ? 
                        (rtdbData['hasDiscount'] as bool? ?? false) : 
                        firestoreProduct.hasDiscount;
                    
                    // Merge the product data
                    mergedProducts.add(firestoreProduct.copyWith(
                      price: price,
                      mrp: mrp,
                      inStock: inStock,
                      hasDiscount: hasDiscount,
                    ) as ProductModel);
                  } else {
                    // Fallback: create product just from RTDB data if no Firestore data available
                    if (value is Map<dynamic, dynamic>) {
                      final rtdbProduct = _parseProductFromRTDBSnapshot(
                        productId, 
                        value, 
                        categoryGroup, 
                        categoryItem
                      );
                      
                      if (rtdbProduct != null) {
                        mergedProducts.add(rtdbProduct);
                      }
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('RTDB: Error merging product $key: $e');
                  }
                }
              });
            }
          }
          
          // Only emit if the data actually changed
          final cachedProducts = _productCache[categoryItem];
          if (cachedProducts == null || !_areProductListsEqual(cachedProducts, mergedProducts)) {
            _productCache[categoryItem] = mergedProducts;
            controller.add(mergedProducts);
            
            if (kDebugMode) {
              print('RTDB: Emitted ${mergedProducts.length} products for category $categoryItem');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('RTDB: Error processing data for $categoryItem: $e');
          }
          
          // Use cached data if available, otherwise empty list
          final cachedProducts = _productCache[categoryItem];
          controller.add(cachedProducts ?? []);
        }
      }, onError: (error) {
        if (kDebugMode) {
          print('RTDB: Error in database listener for $categoryItem: $error');
        }
        controller.addError(error);
      });
      
      // Store the listener to be able to cancel it later
      _listeners[categoryItem] = listener;
    }).catchError((error) {
      if (kDebugMode) {
        print('RTDB: Error loading Firestore data for $categoryItem: $error');
      }
      controller.addError(error);
    });
    
    // Return the stream from the controller
    return controller.stream.asBroadcastStream(onCancel: (subscription) {
      // This ensures the controller is closed when all subscriptions are cancelled
      controller.close();
    });
  }
  
  /// Load static product data from Firestore (once per category)
  Future<List<ProductModel>> _loadFirestoreProductData(String categoryGroup, String categoryItem) async {
    try {
      final productsSnapshot = await _firestore
          .collection('products')
          .doc(categoryGroup)
          .collection('items')
          .doc(categoryItem)
          .collection('products')
          .get();
      
      final products = <ProductModel>[];
      
      for (var doc in productsSnapshot.docs) {
        try {
          final data = doc.data();
          final String id = doc.id;
          
          // Get image URL
          final imagePath = data['imagePath'] ??
              data['image'] ??
              data['imageUrl'] ??
              data['photo'] ??
              data['downloadURL'] ??
              '';
              
          // Use cached image URLs to avoid unnecessary Storage API calls
          final imageUrl = await _getImageUrl(imagePath, id);
          
          // Create product model from Firestore data
          final double price = data['price'] != null 
              ? (data['price'] is int) 
                  ? (data['price'] as int).toDouble() 
                  : (data['price'] as num).toDouble() 
              : 0.0;
              
          final double? mrp = data['mrp'] != null 
              ? (data['mrp'] is int) 
                  ? (data['mrp'] as int).toDouble() 
                  : (data['mrp'] as num).toDouble() 
              : null;
              
          products.add(ProductModel(
            id: id,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            price: price, // Default from Firestore, will be updated from RTDB
            mrp: mrp,     // Default from Firestore, will be updated from RTDB
            image: imageUrl,
            inStock: data['inStock'] ?? true, // Will be updated from RTDB
            categoryId: categoryItem,
            categoryName: data['categoryName'] ?? categoryGroup,
            subcategoryId: categoryItem,
            brand: data['brand'] as String?,
            weight: data['weight'] as String?,
            categoryGroup: categoryGroup,
            ingredients: data['ingredients'] as String?,
            nutritionalInfo: data['nutritionalInfo'] as String?,
            productType: data['productType'] as String?,
            sku: data['sku'] as String?,
            hasDiscount: data['hasDiscount'] as bool? ?? false,
          ));
        } catch (e) {
          if (kDebugMode) {
            print('RTDB: Error parsing Firestore product ${doc.id}: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('RTDB: Loaded ${products.length} products from Firestore for category $categoryItem');
      }
      
      return products;
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Error fetching Firestore products for $categoryGroup > $categoryItem: $e');
      }
      rethrow;
    }
  }
  
  /// Parse product data from RTDB snapshot (fallback when no Firestore data is available)
  ProductModel? _parseProductFromRTDBSnapshot(
    String productId,
    Map<dynamic, dynamic> data,
    String categoryGroup,
    String categoryItem
  ) {
    try {
      final productData = Map<String, dynamic>.from(
        data.map((k, v) => MapEntry(k.toString(), v))
      );
      
      // Extract price with proper type handling
      double price = 0.0;
      if (productData.containsKey('price') && productData['price'] != null) {
        if (productData['price'] is int) {
          price = (productData['price'] as int).toDouble();
        } else if (productData['price'] is double) {
          price = productData['price'] as double;
        } else if (productData['price'] is num) {
          price = (productData['price'] as num).toDouble();
        }
      }
      
      // Extract mrp with proper type handling
      double? mrp = null;
      if (productData.containsKey('mrp') && productData['mrp'] != null) {
        if (productData['mrp'] is int) {
          mrp = (productData['mrp'] as int).toDouble();
        } else if (productData['mrp'] is double) {
          mrp = productData['mrp'] as double;
        } else if (productData['mrp'] is num) {
          mrp = (productData['mrp'] as num).toDouble();
        }
      }
      
      return ProductModel(
        id: productId,
        name: productData['name'] ?? 'Product $productId',
        description: productData['description'] ?? '',
        price: price,
        mrp: mrp,
        image: '',  // No image path available in RTDB
        inStock: productData['inStock'] as bool? ?? true,
        categoryId: categoryItem,
        categoryName: categoryGroup,
        subcategoryId: categoryItem,
        categoryGroup: categoryGroup,
        hasDiscount: productData['hasDiscount'] as bool? ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Error creating product from RTDB data for $productId: $e');
      }
      return null;
    }
  }
  
  // Cache for image URLs to avoid redundant Storage calls
  final Map<String, String> _imageUrlCache = {};
  
  /// Get image URL from cache or compute a new one (async version)
  Future<String> _getImageUrl(String? imagePath, String productId) async {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check cache first
    if (_imageUrlCache.containsKey(imagePath)) {
      return _imageUrlCache[imagePath]!;
    }
    
    // For HTTP URLs, cache and return them directly
    if (imagePath.startsWith('http')) {
      _imageUrlCache[imagePath] = imagePath;
      return imagePath;
    }
    
    // For Firebase Storage paths, compute URL
    try {
      String url = '';
      
      // Handle Firebase Storage gs:// URLs
      if (imagePath.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        url = await ref.getDownloadURL();
      } else {
        // Otherwise treat it as a storage path
        var storagePath = imagePath;
        if (storagePath.startsWith('/')) {
          storagePath = storagePath.substring(1);
        }
        final ref = _storage.ref().child(storagePath);
        url = await ref.getDownloadURL();
      }
      
      // Cache the URL
      _imageUrlCache[imagePath] = url;
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Error getting image URL for product $productId: $e');
      }
      _imageUrlCache[imagePath] = imagePath; // Cache the original to avoid repeated failures
      return imagePath;
    }
  }
  
  /// Get image URL from cache (sync version for quick access)
  String? _getCachedImageUrl(String? imagePath, String productId) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check cache first
    if (_imageUrlCache.containsKey(imagePath)) {
      return _imageUrlCache[imagePath];
    }
    
    // For HTTP URLs, cache and return directly
    if (imagePath.startsWith('http')) {
      _imageUrlCache[imagePath] = imagePath;
      return imagePath;
    }
    
    // For non-cached paths, trigger async load and return null for now
    _getImageUrl(imagePath, productId).then((url) {
      // URL will be cached by _getImageUrl
    });
    
    return null;
  }
  
  /// Check if two product lists are equal by comparing IDs and essential properties
  bool _areProductListsEqual(List<ProductModel> list1, List<ProductModel> list2) {
    if (list1.length != list2.length) return false;
    
    // Create maps by product ID for efficient comparison
    final map1 = {for (var product in list1) product.id: product};
    
    for (var product in list2) {
      final product1 = map1[product.id];
      if (product1 == null) return false;
      
      // Compare essential properties that would affect the UI
      if (product1.name != product.name ||
          product1.price != product.price ||
          product1.inStock != product.inStock ||
          product1.hasDiscount != product.hasDiscount ||
          product1.image != product.image) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Clear the listener for a specific category to prevent memory leaks
  Future<void> removeListener(String categoryItem) async {
    final listener = _listeners.remove(categoryItem);
    if (listener != null) {
      await listener.cancel();
      if (kDebugMode) {
        print('RTDB: Removed listener for category $categoryItem');
      }
    }
  }
  
  /// Clear all listeners when the repository is no longer needed
  Future<void> dispose() async {
    for (final listener in _listeners.values) {
      await listener.cancel();
    }
    _listeners.clear();
    _databaseRefs.clear();
    _productCache.clear();
    
    if (kDebugMode) {
      print('RTDB: Repository disposed, all listeners cleared');
    }
  }
}