import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/services/firebase/firebase_storage_service.dart';
import 'package:profit_grocery_application/services/firebase/firestore_service.dart';
import 'package:profit_grocery_application/services/logging_service.dart';

/// Service for migrating data from the old Firebase structure to the new structure
class DataMigrationService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Singleton pattern
  static final DataMigrationService _instance = DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();
  
  // Status trackers
  bool _isMigrating = false;
  int _totalTasks = 0;
  int _completedTasks = 0;
  String _currentTask = '';
  
  // Status getters
  bool get isMigrating => _isMigrating;
  double get progress => _totalTasks > 0 ? _completedTasks / _totalTasks : 0.0;
  String get currentTask => _currentTask;
  
  // Status callbacks
  Function(String)? onTaskUpdate;
  Function(double)? onProgressUpdate;
  Function(bool, String)? onMigrationComplete;
  
  void _updateTask(String task) {
    _currentTask = task;
    if (onTaskUpdate != null) {
      onTaskUpdate!(task);
    }
  }
  
  void _updateProgress() {
    _completedTasks++;
    if (onProgressUpdate != null) {
      onProgressUpdate!(progress);
    }
  }
  
  /// Migrate existing products to the new structure
  Future<void> migrateProducts() async {
    if (_isMigrating) {
      return;
    }
    
    try {
      _isMigrating = true;
      _completedTasks = 0;
      
      // Get all products from the main products collection
      _updateTask('Fetching existing products...');
      final List<ProductModel> products = await _firestoreService.getProducts();
      _totalTasks = products.length * 2; // Migrate storage + Firestore for each product
      
      _updateTask('Found ${products.length} products to migrate');
      
      for (final product in products) {
        // Skip products that don't have both categoryId and subcategoryId
        if (product.categoryId.isEmpty || product.subcategoryId == null || product.subcategoryId!.isEmpty) {
          _updateTask('Skipping product ${product.id} - missing category or subcategory ID');
          _updateProgress();
          _updateProgress(); // Skip both tasks for this product
          continue;
        }
        
        // 1. Migrate storage image
        _updateTask('Migrating storage for product ${product.name} (${product.id})');
        await _migrateProductImage(product);
        _updateProgress();
        
        // 2. Update Firestore structure
        _updateTask('Migrating Firestore data for product ${product.name} (${product.id})');
        await _migrateProductData(product);
        _updateProgress();
      }
      
      // Notify completion
      if (onMigrationComplete != null) {
        onMigrationComplete!(true, 'Product migration completed successfully');
      }
    } catch (e) {
      LoggingService.logError('DataMigrationService', 'Error migrating products: $e');
      if (onMigrationComplete != null) {
        onMigrationComplete!(false, 'Error migrating products: $e');
      }
    } finally {
      _isMigrating = false;
    }
  }
  
  /// Migrate a product image from the old storage path to the new one
  Future<void> _migrateProductImage(ProductModel product) async {
    try {
      // Extract image URL to identify current path
      final String imageUrl = product.image;
      
      // Skip if the image URL is empty or doesn't contain product ID
      if (imageUrl.isEmpty || !imageUrl.contains(product.id)) {
        LoggingService.logFirestore('Skipping image migration for ${product.id} - invalid image URL');
        return;
      }
      
      // Current storage path: products/{categoryId}/{productId}/product_image.png
      final String oldStoragePath = 'products/${product.categoryId}/${product.id}/product_image.png';
      
      // New storage path: products/{categoryId}/{subcategoryId}/{productId}/product_image.png
      final String newStoragePath = 'products/${product.categoryId}/${product.subcategoryId}/${product.id}/product_image.png';
      
      // Reference to the current image
      final Reference oldRef = _storage.ref().child(oldStoragePath);
      
      // Reference to the new image location
      final Reference newRef = _storage.ref().child(newStoragePath);
      
      // Check if the old image exists
      try {
        await oldRef.getDownloadURL();
      } catch (e) {
        LoggingService.logFirestore('Original image not found for ${product.id}, selecting random image');
        
        // If old image doesn't exist, upload a random image to the new location
        final int randomIndex = Random().nextInt(10) + 1;
        final String assetPath = 'assets/products/$randomIndex.png';
        
        await _storageService.uploadAssetImage(
          assetPath: assetPath,
          storagePath: 'products/${product.categoryId}/${product.subcategoryId}/${product.id}',
          fileName: 'product_image.png',
        );
        
        return;
      }
      
      // Download data from old location
      final data = await oldRef.getData();
      
      if (data == null) {
        LoggingService.logFirestore( 'Failed to download image data for ${product.id}');
        return;
      }
      
      // Upload to new location
      await newRef.putData(data);
      
      // Get new download URL
      final String newImageUrl = await newRef.getDownloadURL();
      
      // Update product with new image URL
      final ProductModel updatedProduct = product.copyWith(
        id: product.id,
        image: newImageUrl,
        weight: product.weight ?? '',
        brand: product.brand ?? '',
        rating: product.rating ?? 0.0,
        reviewCount: product.reviewCount ?? 0,
      );
      
      // Update product in main collection
      await _firestoreService.addProduct(updatedProduct);
      
      // Attempt to delete the old image (don't throw if this fails)
      try {
        await oldRef.delete();
      } catch (e) {
        LoggingService.logFirestore('Failed to delete old image for ${product.id}: $e');
      }
    } catch (e) {
      LoggingService.logError('DataMigrationService', 'Error migrating product image for ${product.id}: $e');
      rethrow;
    }
  }
  
  /// Migrate a product from the main products collection to the nested subcategory structure
  Future<void> _migrateProductData(ProductModel product) async {
    try {
      // Skip products that don't have both categoryId and subcategoryId
      if (product.categoryId.isEmpty || product.subcategoryId == null || product.subcategoryId!.isEmpty) {
        LoggingService.logFirestore('Skipping data migration for ${product.id} - missing category or subcategory ID');
        return;
      }
      
      // The addProduct method now automatically handles the nested structure
      // Format: /products/{categoryId}/{subcategoryId}/products/items/{productId}
      await _firestoreService.addProduct(product);
      
      LoggingService.logFirestore('Successfully migrated product ${product.id} to products/${product.categoryId}/${product.subcategoryId}/products/items/${product.id}');
    } catch (e) {
      LoggingService.logError('DataMigrationService', 'Error migrating product data for ${product.id}: $e');
      rethrow;
    }
  }
}
