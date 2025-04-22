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
  bool _isCacheInitialized = false;

  // Cache initialization
  Future<void> _initializeCache() async {
    if (_isCacheInitialized) return;
    
    LoggingService.logFirestore('SharedProductService: Initializing product cache');
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

  /// Find a product in Firestore by searching all categories and subcategories
  Future<ProductModel?> _findProductInFirestore(String productId) async {
    try {
      // First try the direct approach - look in the "products" collection
      // Method 1: Direct query if we know the path
      try {
        // Try to get a product directly from all categories
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
                return await _createProductModelFromDoc(productDoc, categoryId, subcategoryId);
              }
            } catch (e) {
              // Continue searching in other subcategories
              LoggingService.logError('SharedProductService', 'Error searching in $categoryId/$subcategoryId: $e');
            }
          }
        }
        
        // If direct approach fails, check if it exists in bestsellers and get information from there
        final bestsellerDoc = await _firestore.collection('bestsellers').doc(productId).get();
        if (bestsellerDoc.exists) {
          print('SharedProductService: Found product ID $productId in bestsellers collection');
          
          // Since the product isn't found in the normal structure, but exists in bestsellers,
          // we need to search for it using a query by ID
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
        LoggingService.logError('SharedProductService', 'Error during direct product lookup: $e');
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
      mrp: (data['mrp'] is int)
          ? (data['mrp'] as int).toDouble()
          : (data['mrp'] as num?)?.toDouble() ?? 0.0,
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

    // If the image path is already a full Firebase Storage URL
    if (nonNullPath.startsWith('https://firebasestorage.googleapis.com')) {
      // Already has a token, return as is
      if (nonNullPath.contains('token=')) {
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
            return await ref.getDownloadURL();
          }
        } catch (e) {
          LoggingService.logError('SharedProductService', 'Error getting fresh download URL for $productId: $e');
          // fall through and return the original
        }
      }

      return nonNullPath;
    }

    // Otherwise treat it as a storage path
    try {
      var storagePath = nonNullPath;
      if (storagePath.startsWith('/')) {
        storagePath = storagePath.substring(1);
      }
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      LoggingService.logError('SharedProductService', 'Error getting download URL for product $productId: $e');
      // Always return a non-null string
      return nonNullPath;
    }
  }
  
  /// Fetch multiple products by IDs at once
  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    final List<Product> products = [];
    
    for (final productId in productIds) {
      final product = await getProductById(productId);
      if (product != null) {
        products.add(product);
      }
    }
    
    return products;
  }

  /// Clear the product cache
  void clearCache() {
    _productCache.clear();
    LoggingService.logFirestore('SharedProductService: Product cache cleared');
  }
}