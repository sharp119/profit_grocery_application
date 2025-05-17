import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/domain/entities/product.dart';
import 'package:profit_grocery_application/services/logging_service.dart';

/// A centralized service for product data access
/// This service provides cached product data and handles Firestore queries efficiently
class SharedProductService {
  // Singleton pattern
  static final SharedProductService _instance = SharedProductService._internal();
  
  factory SharedProductService() => _instance;
  
  SharedProductService._internal() {
    _initializeCache();
  }

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Cache for products
  final Map<String, ProductModel> _productCache = {};
  // Cache for image URLs to avoid resolving the same URL multiple times
  final Map<String, String> _imageUrlCache = {};
  bool _isCacheInitialized = false;
  
  // Store categories and subcategories structure to avoid repeated queries
  Map<String, List<String>> _categoriesAndSubcategories = {};

  // Cache initialization
  Future<void> _initializeCache() async {
    if (_isCacheInitialized) return;
    
    LoggingService.logFirestore('SharedProductService: Initializing product cache');
    
    try {
      // Pre-fetch categories and subcategories structure to speed up future lookups
      final categoriesSnapshot = await _firestore.collection('products').get();
      
      for (final categoryDoc in categoriesSnapshot.docs) {
        final categoryId = categoryDoc.id;
        final subcategories = <String>[];
        
        final subcategoriesSnapshot = await _firestore.collection('products')
            .doc(categoryId)
            .collection('items')
            .get();
        
        for (final subcategoryDoc in subcategoriesSnapshot.docs) {
          subcategories.add(subcategoryDoc.id);
        }
        
        _categoriesAndSubcategories[categoryId] = subcategories;
      }
      
      LoggingService.logFirestore('SharedProductService: Pre-fetched structure for ${_categoriesAndSubcategories.length} categories');
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error initializing cache: $e');
    }
    
    _isCacheInitialized = true;
  }

  /// Get a product by ID with caching
  /// This is the main method for getting product details anywhere in the app
  Future<Product?> getProductById(String productId) async {
    try {
      // Log that we're trying to get a product
      print('SharedProductService: Trying to get product by ID: $productId');
      LoggingService.logFirestore('SharedProductService: Trying to get product by ID: $productId');
      
      // Check cache first
      if (_productCache.containsKey(productId)) {
        LoggingService.logFirestore('SharedProductService: Cache hit for product $productId');
        print('SharedProductService: Cache hit for product $productId');
        return _productCache[productId]!;
      }
      
      LoggingService.logFirestore('SharedProductService: Cache miss for product $productId, fetching from Firestore');
      
      // Find the product in Firestore
      ProductModel? product = await _findProductInFirestore(productId);
      
      // Cache the result (even if null, to prevent repeated failed lookups)
      if (product != null) {
        print('SharedProductService: Found product in Firestore: ${product.id}, name=${product.name}, categoryName=${product.categoryName}, categoryId=${product.categoryId}, subcategoryId=${product.subcategoryId}');
        LoggingService.logFirestore('SharedProductService: Found product in Firestore: ${product.id}, name=${product.name}, categoryName=${product.categoryName}, categoryId=${product.categoryId}, subcategoryId=${product.subcategoryId}');
        _productCache[productId] = product;
      } else {
        print('SharedProductService: Product $productId not found in Firestore');
        LoggingService.logFirestore('SharedProductService: Product $productId not found in Firestore');
      }
      
      return product;
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error getting product $productId: $e');
      return null;
    }
  }

  /// Find a product in Firestore using optimized lookup strategies
  Future<ProductModel?> _findProductInFirestore(String productId) async {
    try {
      // Try more efficient lookup methods first
      
      // Method 1: Check if it exists in bestsellers (optimization for bestsellers section)
      // This is faster than searching through all categories and subcategories
      try {
        final bestsellerDoc = await _firestore.collection('bestsellers').doc(productId).get();
        if (bestsellerDoc.exists) {
          print('SharedProductService: Found product ID $productId in bestsellers collection');
          
          // Use collectionGroup query to find the product by ID across all collections
          final querySnapshot = await _firestore.collectionGroup('products')
              .where(FieldPath.documentId, isEqualTo: productId)
              .limit(1)
              .get();
              
          if (querySnapshot.docs.isNotEmpty) {
            final productDoc = querySnapshot.docs.first;
            // Extract category info from the reference path
            final path = productDoc.reference.path;
            print('SharedProductService: Found product through query by ID - Path: $path');
            
            // Parse path "products/categoryId/items/subcategoryId/products/productId"
            final pathSegments = path.split('/');
            if (pathSegments.length >= 6) {
              final categoryId = pathSegments[1];
              final subcategoryId = pathSegments[3];
              return await _createProductModelFromDoc(productDoc, categoryId, subcategoryId);
            }
          } else {
            print('SharedProductService: Product ID $productId exists in bestsellers but not found in products collection');
            
            // If we have a "products" doc with the same ID, try to get its data directly
            final productDoc = await _firestore.collection('products').doc(productId).get();
            if (productDoc.exists) {
              final data = productDoc.data() as Map<String, dynamic>?;
              if (data != null) {
                print('SharedProductService: Found product data in direct products collection');
                // Create a basic product model from whatever data is available
                return _createBasicProductModelFromData(productId, data);
              }
            }
          }
        }
      } catch (e) {
        LoggingService.logError('SharedProductService', 'Error checking bestsellers: $e');
      }
      
      // Method 2: Look through known categories and subcategories (using pre-cached structure)
      if (_categoriesAndSubcategories.isNotEmpty) {
        for (final entry in _categoriesAndSubcategories.entries) {
          final categoryId = entry.key;
          final subcategories = entry.value;
          
          for (final subcategoryId in subcategories) {
            try {
              final productDoc = await _firestore.collection('products')
                  .doc(categoryId)
                  .collection('items')
                  .doc(subcategoryId)
                  .collection('products')
                  .doc(productId)
                  .get();
              
              if (productDoc.exists) {
                print('SharedProductService: Found product $productId in category $categoryId, subcategory $subcategoryId');
                return await _createProductModelFromDoc(productDoc, categoryId, subcategoryId);
              }
            } catch (e) {
              // Continue searching in other subcategories
              LoggingService.logError('SharedProductService', 'Error searching in $categoryId/$subcategoryId: $e');
            }
          }
        }
      }
      
      // Method 3: Fallback to slow search if structure not cached
      // Slower method - search through all categories and subcategories
      if (_categoriesAndSubcategories.isEmpty) {
        final categoriesSnapshot = await _firestore.collection('products').get();
        
        for (final categoryDoc in categoriesSnapshot.docs) {
          final categoryId = categoryDoc.id;
          
          // Get subcategories in this category
          final subcategoriesSnapshot = await _firestore.collection('products')
              .doc(categoryId)
              .collection('items')
              .get();
          
          for (final subcategoryDoc in subcategoriesSnapshot.docs) {
            final subcategoryId = subcategoryDoc.id;
            
            // Try to find the product in this subcategory
            try {
              final productDoc = await _firestore.collection('products')
                  .doc(categoryId)
                  .collection('items')
                  .doc(subcategoryId)
                  .collection('products')
                  .doc(productId)
                  .get();
              
              if (productDoc.exists) {
                print('SharedProductService: Found product $productId in category $categoryId, subcategory $subcategoryId');
                
                // Cache this category/subcategory pair for future lookups
                if (!_categoriesAndSubcategories.containsKey(categoryId)) {
                  _categoriesAndSubcategories[categoryId] = [];
                }
                if (!_categoriesAndSubcategories[categoryId]!.contains(subcategoryId)) {
                  _categoriesAndSubcategories[categoryId]!.add(subcategoryId);
                }
                
                return await _createProductModelFromDoc(productDoc, categoryId, subcategoryId);
              }
            } catch (e) {
              // Continue searching in other subcategories
              LoggingService.logError('SharedProductService', 'Error searching in $categoryId/$subcategoryId: $e');
            }
          }
        }
      }
      
      // If we get here, the product was not found
      return null;
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error finding product in Firestore: $e');
      return null;
    }
  }
  
  /// Create a basic product model from partial data
  /// Used when we only have limited information about a product
  ProductModel _createBasicProductModelFromData(String productId, Map<String, dynamic> data) {
    return ProductModel(
      id: productId,
      name: data['name'] ?? 'Product $productId',
      description: data['description'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] as num?)?.toDouble() ?? 0.0,
      // mrp: (data['mrp'] is int)
      //     ? (data['mrp'] as int).toDouble()
      //     : (data['mrp'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] ?? data['imagePath'] ?? '',
      inStock: data['inStock'] ?? true,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      brand: data['brand'] as String?,
      weight: data['weight'] as String?,
    );
  }
  
  /// Create a ProductModel from a DocumentSnapshot, handling image URL resolution
  Future<ProductModel> _createProductModelFromDoc(
    DocumentSnapshot doc, 
    String categoryId, 
    String subcategoryId
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Find image path in different possible field names
    final imagePath = data['imagePath'] ??
        data['image'] ??
        data['imageUrl'] ??
        data['photo'] ??
        data['downloadURL'] ??
        '';
    
    // Resolve image URL
    final imageUrl = await _getImageUrl(imagePath, doc.id);
    
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (data['mrp'] is int)
          ? (data['mrp'] as int).toDouble()
          : (data['mrp'] as num?)?.toDouble() ?? 0.0,
      image: imageUrl,
      inStock: data['inStock'] ?? true,
      categoryId: data['categoryItem'] ?? subcategoryId,
      categoryName: data['categoryGroup'] ?? categoryId,
      subcategoryId: subcategoryId,
      brand: data['brand'] as String?,
      weight: data['weight'] as String?,
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      reviewCount: data['reviewCount'] as int?,
    );
  }
  
  /// Get a properly formatted image URL from various possible formats
  Future<String> _getImageUrl(String? imagePath, String productId) async {
    // If there's no path, just return empty string
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Promote to non-nullable local variable
    final nonNullPath = imagePath;
    
    // Check image URL cache first
    if (_imageUrlCache.containsKey(nonNullPath)) {
      return _imageUrlCache[nonNullPath]!;
    }

    // If the image path is already a full Firebase Storage URL
    if (nonNullPath.startsWith('https://firebasestorage.googleapis.com')) {
      // Already has a token, return as is
      if (nonNullPath.contains('token=')) {
        _imageUrlCache[nonNullPath] = nonNullPath;
        return nonNullPath;
      }

      // Has alt=media but no token: try to refresh the URL
      if (nonNullPath.contains('alt=media') && !nonNullPath.contains('token=')) {
        try {
          final uri = Uri.parse(nonNullPath);
          final segments = uri.pathSegments;
          if (segments.contains('o') && segments.length > segments.indexOf('o') + 1) {
            final objectPath = Uri.decodeFull(segments[segments.indexOf('o') + 1]);
            final ref = _storage.ref().child(objectPath);
            final url = await ref.getDownloadURL();
            _imageUrlCache[nonNullPath] = url;
            return url;
          }
        } catch (e) {
          LoggingService.logError('SharedProductService', 'Error getting fresh download URL for $productId: $e');
          // fall through and return the original
        }
      }

      _imageUrlCache[nonNullPath] = nonNullPath;
      return nonNullPath;
    }

    // Otherwise treat it as a storage path
    try {
      var storagePath = nonNullPath;
      if (storagePath.startsWith('/')) {
        storagePath = storagePath.substring(1);
      }
      final ref = _storage.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      _imageUrlCache[nonNullPath] = url;
      return url;
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error getting download URL for product $productId: $e');
      // Always return a non-null string
      _imageUrlCache[nonNullPath] = nonNullPath;
      return nonNullPath;
    }
  }
  
  /// Fetch multiple products by IDs at once with optimized batch loading
  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    // Group product IDs by cache status
    final List<String> cachedProductIds = [];
    final List<String> nonCachedProductIds = [];
    
    for (final id in productIds) {
      if (_productCache.containsKey(id)) {
        cachedProductIds.add(id);
      } else {
        nonCachedProductIds.add(id);
      }
    }
    
    // Get cached products immediately
    final List<Product> products = cachedProductIds
        .map((id) => _productCache[id]!)
        .toList();
    
    // If all products are cached, return them directly
    if (nonCachedProductIds.isEmpty) {
      return products;
    }
    
    // Try to batch-load bestseller products first (more efficient for the bestseller section)
    if (nonCachedProductIds.isNotEmpty) {
      try {
        // First check bestsellers collection for these products
        final bestsellerDocs = await _firestore.collection('bestsellers')
            .where(FieldPath.documentId, whereIn: nonCachedProductIds.length > 10 
                ? nonCachedProductIds.sublist(0, 10) 
                : nonCachedProductIds)
            .get();
        
        // Build a map of found products in bestsellers
        final bestsellerProductIds = bestsellerDocs.docs.map((doc) => doc.id).toSet();
        
        // If we found any in bestsellers, use collectionGroup query to get them
        if (bestsellerProductIds.isNotEmpty) {
          final foundProducts = await _batchLoadProductsById(bestsellerProductIds.toList());
          products.addAll(foundProducts);
          
          // Remove found products from the non-cached list
          nonCachedProductIds.removeWhere((id) => bestsellerProductIds.contains(id));
        }
      } catch (e) {
        LoggingService.logError('SharedProductService', 'Error batch-loading bestseller products: $e');
      }
    }
    
    // For any remaining non-cached products, load them individually
    for (final productId in nonCachedProductIds) {
      final product = await getProductById(productId);
      if (product != null) {
        products.add(product);
      }
    }
    
    return products;
  }
  
  /// Load multiple products by ID using collectionGroup query
  Future<List<Product>> _batchLoadProductsById(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    
    try {
      print('SharedProductService: Batch loading ${productIds.length} products');
      final products = <Product>[];
      
      // Use collectionGroup to find products across all collections
      final querySnapshot = await _firestore.collectionGroup('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();
      
      // Process each found product
      for (final doc in querySnapshot.docs) {
        try {
          final path = doc.reference.path;
          final pathSegments = path.split('/');
          
          if (pathSegments.length >= 6) {
            final categoryId = pathSegments[1];
            final subcategoryId = pathSegments[3];
            
            final product = await _createProductModelFromDoc(doc, categoryId, subcategoryId);
            products.add(product);
            
            // Cache the product
            _productCache[product.id] = product;
          }
        } catch (e) {
          LoggingService.logError('SharedProductService', 'Error processing product ${doc.id}: $e');
        }
      }
      
      return products;
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error batch loading products: $e');
      return [];
    }
  }

  /// Clear the product cache
  void clearCache() {
    _productCache.clear();
    _imageUrlCache.clear();
    LoggingService.logFirestore('SharedProductService: Product cache cleared');
  }
}