import 'dart:async'; // Make sure this is imported
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../domain/entities/product.dart';
import '../services/logging_service.dart'; // Or your preferred logger

class RTDBProductService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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

  // New method to provide a real-time stream for a single product
  Stream<Product?> getProductStream(String productId) {
    try {
      return _database.ref('dynamic_product_info/$productId').onValue.map((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          // Use the existing parser to convert snapshot data to Product object
          return parseProductFromRTDB(productId, Map<dynamic, dynamic>.from(event.snapshot.value as Map));
        } else {
          LoggingService.logFirestore('RTDBProductService: Product stream for $productId - Data not found or null.');
          return null;
        }
      }).handleError((error) {
        LoggingService.logError('RTDBProductService', 'Error in product stream for $productId: $error');
        return null; // Return null on error to indicate no product data
      });
    } catch (e) {
      LoggingService.logError('RTDBProductService', 'Failed to set up product stream for $productId: $e');
      return Stream.value(null); // Return a stream with a single null value on setup failure
    }
  }

  Product? parseProductFromRTDB(String productId, Map<dynamic, dynamic> data) {
    try {
      final String? name = data['name']?.toString();
      final String? brand = data['brand']?.toString();
      final String? weight = data['weight']?.toString();
      final String? path = data['path']?.toString();
      final String? imagePath = data['imagePath']?.toString();
      final bool inStock = data['inStock'] as bool? ?? true;
      final int stockQuantity = data['quantity'] as int? ?? 0;

      final double mrp = _parseDouble(data['mrp']) ?? 0.0;

      final Map<dynamic, dynamic>? discountData = data['discount'] as Map<dynamic, dynamic>?;
      final bool hasDiscountFeatureEnabled = data['hasDiscount'] as bool? ?? false;

      double finalPrice = mrp;
      String? discountType;
      double? discountValue;
      bool isDiscountCurrentlyActiveAndApplied = false;

      if (hasDiscountFeatureEnabled && discountData != null) {
        discountType = discountData['type']?.toString();
        discountValue = _parseDouble(discountData['value']);
        final bool isActiveByFlag = discountData['isActive'] as bool? ?? false;

        if (isActiveByFlag && discountType != null && discountValue != null) {
          final int? startTime = discountData['start'] as int?;
          final int? endTime = discountData['end'] as int?;
          final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

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

            isDiscountCurrentlyActiveAndApplied = finalPrice < mrp;
          }
        }
      }

      final int? colorValue = data['itemBackgroundColor'] as int?;
      Color? itemBackgroundColor;
      if (colorValue != null) {
        itemBackgroundColor = Color(colorValue);
      }

      if (name == null) {
        print('RTDBProductService: Missing name for product $productId. Skipping.');
        return null;
      }

      return Product(
        id: productId,
        name: name,
        description: '$brand ${weight ?? ''}'.trim(),
        price: finalPrice,
        mrp: isDiscountCurrentlyActiveAndApplied ? mrp : null,
        image: imagePath ?? '',
        categoryId: data['categoryId']?.toString() ?? data['categoryID']?.toString() ?? '',
        categoryName: data['categoryName']?.toString() ?? path?.split('/').first ?? '',
        subcategoryId: data['subcategoryId']?.toString() ?? data['subcategoryID']?.toString() ?? '',
        tags: (data['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? const [],
        weight: weight,
        brand: brand,
        inStock: inStock && stockQuantity > 0,
        customProperties: {
          'itemBackgroundColor': itemBackgroundColor,
          'hasDiscount': isDiscountCurrentlyActiveAndApplied,
          'discountType': discountType,
          'discountValue': discountValue,
          'stockQuantity': stockQuantity,
          'categoryPath': path,
          'originalImagePath': imagePath,
          'rawMrp': mrp,
        },
      );
    } catch (e) {
      print('RTDBProductService ERROR: Failed to parse product $productId - $e');
      return null;
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final snapshot = await _database.ref('dynamic_product_info/$productId').get();
      if (snapshot.exists && snapshot.value != null) {
        return parseProductFromRTDB(productId, Map<dynamic, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      LoggingService.logError('RTDBProductService', 'Error getting product by ID: $e');
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