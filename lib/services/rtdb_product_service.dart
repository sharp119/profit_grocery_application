// lib/services/rtdb_product_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // For Color, if parsing color
import '../domain/entities/product.dart'; // Your Product entity
// Assuming LoggingService exists as per your rtdb_bestseller_repository.dart
// If not, use print or your preferred logging solution.
import '../services/logging_service.dart'; // Or your preferred logger

class RTDBProductService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Fetches complete product information for a list of product IDs from RTDB.
  Future<List<Product>> getProductsDetails(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    // LoggingService.logInfo('RTDBProductService: Fetching details for ${productIds.length} products: $productIds');

    List<Product> products = [];
    final productInfoRef = _database.ref('dynamic_product_info');

    for (final productId in productIds) {
      try {
        final productSnapshot = await productInfoRef.child(productId).get();
        if (productSnapshot.exists && productSnapshot.value != null) {
          final productData = Map<dynamic, dynamic>.from(productSnapshot.value as Map);
          final product = parseProductFromRTDB(productId, productData);
          if (product != null) {
            products.add(product);
          } else {
            // LoggingService.logWarning('RTDBProductService: Failed to parse product $productId');
            print('RTDBProductService: Failed to parse product $productId');
          }
        } else {
          // LoggingService.logWarning('RTDBProductService: Product data not found for ID: $productId in dynamic_product_info');
          print('RTDBProductService: Product data not found for ID: $productId in dynamic_product_info');
        }
      } catch (e) {
        // LoggingService.logError('RTDBProductService', 'Error getting product $productId: $e');
        print('RTDBProductService ERROR: Error getting product $productId: $e');
      }
    }
    // LoggingService.logInfo('RTDBProductService: Successfully fetched ${products.length} products.');
    return products;
  }

  /// Parses product data from RTDB structure to Product entity.
  /// This should be based on the structure of your `dynamic_product_info` node
  /// and the parsing logic in RTDBBestsellerRepository._parseProductFromRTDB.
  Product? parseProductFromRTDB(String productId, Map<dynamic, dynamic> data) {
    try {
      final String? name = data['name']?.toString();
      final String? brand = data['brand']?.toString();
      final String? weight = data['weight']?.toString();
      final String? path = data['path']?.toString();
      final String? imagePath = data['imagePath']?.toString(); // Expecting full Firebase Storage URL
      final bool inStock = data['inStock'] as bool? ?? true;
      final int stockQuantity = data['quantity'] as int? ?? 0; // Renamed from 'quantity' to avoid clash with cart quantity

      final double mrp = _parseDouble(data['mrp']) ?? 0.0;

      final Map<dynamic, dynamic>? discountData = data['discount'] as Map<dynamic, dynamic>?;
      final bool hasDiscountFeatureEnabled = data['hasDiscount'] as bool? ?? false; // Flag from DB if discount *can* be applied

      double finalPrice = mrp;
      String? discountType;
      double? discountValue;
      bool isDiscountCurrentlyActiveAndApplied = false;

      if (hasDiscountFeatureEnabled && discountData != null) {
        discountType = discountData['type']?.toString();
        discountValue = _parseDouble(discountData['value']);
        final bool isActiveByFlag = discountData['isActive'] as bool? ?? false; // Discount active flag

        if (isActiveByFlag && discountType != null && discountValue != null) {
          final int? startTime = discountData['start'] as int?; // Unix timestamp in seconds
          final int? endTime = discountData['end'] as int?;   // Unix timestamp in seconds
          final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current time in seconds

          bool isInTimeRange = true;
          if (startTime != null && endTime != null) {
            isInTimeRange = currentTime >= startTime && currentTime <= endTime;
          } else if (startTime != null) {
            isInTimeRange = currentTime >= startTime;
          } else if (endTime != null) {
            isInTimeRange = currentTime <= endTime;
          }

          if (isInTimeRange) {
            if (discountType.toLowerCase() == 'percentage') {
              finalPrice = mrp * (1 - (discountValue / 100));
            } else if (discountType.toLowerCase() == 'flat') {
              finalPrice = mrp - discountValue;
            }
            if (finalPrice < 0) finalPrice = 0.0;

            // A discount is considered applied if finalPrice is less than MRP due to this logic
            isDiscountCurrentlyActiveAndApplied = finalPrice < mrp;
          }
        }
      }

      final int? colorValue = data['itemBackgroundColor'] as int?;
      Color? itemBackgroundColor; // Material Color
      if (colorValue != null) {
        itemBackgroundColor = Color(colorValue);
      }

      if (name == null) {
        // LoggingService.logWarning('RTDBProductService: Missing name for product $productId. Skipping.');
        print('RTDBProductService: Missing name for product $productId. Skipping.');
        return null;
      }

      return Product(
        id: productId,
        name: name,
        description: '$brand ${weight ?? ''}'.trim(), // Or from a dedicated description field
        price: finalPrice, // This is the FINAL price after active discount
        mrp: isDiscountCurrentlyActiveAndApplied ? mrp : null, // Show MRP only if a discount was applied making finalPrice < mrp
        image: imagePath ?? '',
        categoryId: path?.split('/').first ?? '', // Example
        categoryName: path?.split('/').first ?? '', // Example
        subcategoryId: '', // Example
        tags: [brand, weight].where((tag) => tag != null && tag.isNotEmpty).cast<String>().toList(),
        weight: weight,
        brand: brand,
        inStock: inStock && stockQuantity > 0, // Actual stock status
        // Use customProperties to store any additional RTDB-specific fields
        // that don't directly map to Product entity fields but are needed for display logic.
        customProperties: {
          'itemBackgroundColor': itemBackgroundColor,
          'hasDiscount': isDiscountCurrentlyActiveAndApplied, // True if a discount *is currently making the price lower*
          'discountType': discountType, // Original discount type
          'discountValue': discountValue, // Original discount value
          'stockQuantity': stockQuantity, // Available stock
          'categoryPath': path,
          'originalImagePath': imagePath, // For debugging if needed
          'rawMrp': mrp, // Store raw MRP for calculations if needed elsewhere
        },
      );
    } catch (e) {
      // LoggingService.logError('RTDBProductService', 'Error parsing product $productId: $e');
      print('RTDBProductService ERROR: Failed to parse product $productId - $e');
      return null;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}