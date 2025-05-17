import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../services/logging_service.dart';

/// Utility class to generate sample data for RTDB testing
class RTDBSampleDataGenerator {
  final _database = FirebaseDatabase.instance;
  final _random = Random();

  /// Generate a random price between min and max with 1 decimal place
  double _randomPrice(double min, double max) {
    return (min + _random.nextDouble() * (max - min)).roundToDouble() / 10;
  }

  /// Update price for a product at a specific path
  Future<bool> updateProductPrice(String path, double newPrice) async {
    try {
      LoggingService.logFirestore('RTDB_SAMPLE_DATA: Updating price at $path to \$${newPrice.toStringAsFixed(2)}');
      
      await _database.ref(path).update({
        'price': newPrice,
        'updatedAt': ServerValue.timestamp,
      });
      
      return true;
    } catch (e) {
      LoggingService.logError('RTDB_SAMPLE_DATA', 'Error updating price at $path: $e');
      return false;
    }
  }

  /// Toggle in-stock status for a product
  Future<bool> toggleProductStock(String path, bool inStock) async {
    try {
      LoggingService.logFirestore('RTDB_SAMPLE_DATA: Setting stock status at $path to $inStock');
      
      await _database.ref(path).update({
        'inStock': inStock,
        'updatedAt': ServerValue.timestamp,
      });
      
      return true;
    } catch (e) {
      LoggingService.logError('RTDB_SAMPLE_DATA', 'Error updating stock status at $path: $e');
      return false;
    }
  }

  /// Update price for a product by product ID
  Future<bool> updateProductPriceById(String productId, double newPrice) async {
    try {
      // Check if we have a product index that maps product IDs to paths
      final indexRef = _database.ref('product_index/$productId');
      final indexSnapshot = await indexRef.get();
      
      if (indexSnapshot.exists && indexSnapshot.value != null) {
        final path = indexSnapshot.value as String;
        return await updateProductPrice(path, newPrice);
      }
      
      // No index found, search for product manually
      LoggingService.logFirestore('RTDB_SAMPLE_DATA: No index for $productId, searching categories...');
      
      // Known category groups for searching
      final knownCategoryGroups = [
        'bakeries_biscuits',
        'beauty_hygiene',
        'dairy_eggs',
        'fruits_vegetables',
        'grocery_kitchen',
        'snacks_drinks'
      ];
      
      // Search in all category groups
      for (final categoryGroup in knownCategoryGroups) {
        final categoryItemsRef = _database.ref('products/$categoryGroup/items');
        final categoryItemsSnapshot = await categoryItemsRef.get();
        
        if (!categoryItemsSnapshot.exists) continue;
        
        final categoryItems = categoryItemsSnapshot.value as Map<dynamic, dynamic>;
        
        // Search in all category items
        for (final categoryItem in categoryItems.keys) {
          final path = 'products/$categoryGroup/items/$categoryItem/products/$productId';
          final productRef = _database.ref(path);
          final productSnapshot = await productRef.get();
          
          if (productSnapshot.exists) {
            // Add to index for future lookups
            await _database.ref('product_index/$productId').set(path);
            return await updateProductPrice(path, newPrice);
          }
        }
      }
      
      LoggingService.logError('RTDB_SAMPLE_DATA', 'Could not find product $productId in any category');
      return false;
    } catch (e) {
      LoggingService.logError('RTDB_SAMPLE_DATA', 'Error updating price for product $productId: $e');
      return false;
    }
  }

  /// Randomly update prices for multiple products in a category
  Future<int> randomizeCategoryPrices(String categoryGroup, String categoryItem) async {
    try {
      final productsPath = 'products/$categoryGroup/items/$categoryItem/products';
      final productsRef = _database.ref(productsPath);
      final snapshot = await productsRef.get();
      
      if (!snapshot.exists) {
        LoggingService.logError('RTDB_SAMPLE_DATA', 'No products found at $productsPath');
        return 0;
      }
      
      final productsMap = snapshot.value as Map<dynamic, dynamic>;
      int updatedCount = 0;
      
      for (final productId in productsMap.keys) {
        final productPath = '$productsPath/$productId';
        final newPrice = _randomPrice(100.0, 999.9);
        
        final success = await updateProductPrice(productPath, newPrice);
        if (success) updatedCount++;
      }
      
      LoggingService.logFirestore('RTDB_SAMPLE_DATA: Updated $updatedCount prices in $categoryGroup/$categoryItem');
      return updatedCount;
    } catch (e) {
      LoggingService.logError('RTDB_SAMPLE_DATA', 'Error randomizing category prices: $e');
      return 0;
    }
  }
} 