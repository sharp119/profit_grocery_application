import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product/shared_product_service.dart';

/// Service for handling product discount calculations and related operations
/// This centralized service ensures consistent discount handling across different product cards
class DiscountService {
  /// Cache to store discount information by product ID
  static final Map<String, Map<String, dynamic>> _discountCache = {};
  
  /// Calculate the final price after applying a discount
  /// 
  /// Parameters:
  /// - [originalPrice]: The original product price
  /// - [discountType]: Type of discount ('percentage' or 'flat')
  /// - [discountValue]: Value of the discount (percentage or fixed amount)
  /// - [productId]: Optional product ID for logging purposes
  /// 
  /// Returns the final price after discount
  static double calculateFinalPrice({
    required double originalPrice,
    required String? discountType,
    required double? discountValue,
    String? productId,
  }) {
    if (discountType == null || discountValue == null || discountValue <= 0) {
      if (productId != null) {
        logDiscount(productId: productId, discountType: null, discountValue: null);
      }
      return originalPrice;
    }
    
    double finalPrice = originalPrice;
    
    if (discountType == 'percentage') {
      final discount = originalPrice * (discountValue / 100);
      finalPrice = originalPrice - discount;
    } else if (discountType == 'flat') {
      finalPrice = originalPrice - discountValue;
    }
    
    // Log discount info if product ID is provided
    if (productId != null) {
      logDiscount(
        productId: productId,
        discountType: discountType,
        discountValue: discountValue
      );
    }
    
    // Ensure final price is not negative
    return finalPrice < 0 ? 0 : finalPrice;
  }
  
  /// Determine if a product has a valid discount
  /// 
  /// Parameters:
  /// - [discountType]: Type of discount ('percentage' or 'flat')
  /// - [discountValue]: Value of the discount
  /// - [productId]: Optional product ID for logging purposes
  /// 
  /// Returns true if the product has a valid discount
  static bool hasDiscount({
    required String? discountType,
    required double? discountValue,
    String? productId,
  }) {
    bool result = discountType != null && discountValue != null && discountValue > 0;
    
    // Log discount info if product ID is provided
    if (productId != null) {
      logDiscount(
        productId: productId,
        discountType: discountType,
        discountValue: discountValue
      );
    }
    
    return result;
  }
  
  /// Calculate the discount percentage between original and final price
  /// 
  /// Parameters:
  /// - [originalPrice]: The original/list price (usually MRP)
  /// - [finalPrice]: The final price after discounts
  /// - [productId]: Optional product ID for logging purposes
  /// 
  /// Returns the discount percentage rounded to nearest integer
  static int calculateDiscountPercentage({
    required double originalPrice,
    required double finalPrice,
    String? productId,
  }) {
    if (originalPrice <= 0 || finalPrice >= originalPrice) {
      return 0;
    }
    
    final percentage = ((originalPrice - finalPrice) / originalPrice * 100).round();
    
    // Log discount info if product ID is provided
    if (productId != null) {
      final discountValue = originalPrice - finalPrice;
      logDiscount(
        productId: productId,
        discountType: 'calculated', 
        discountValue: discountValue
      );
    }
    
    return percentage;
  }
  
  /// Get the display text for a discount
  /// 
  /// Parameters:
  /// - [discountType]: Type of discount ('percentage' or 'flat')
  /// - [discountValue]: Value of the discount
  /// - [currencySymbol]: Symbol for currency (for flat discounts)
  /// 
  /// Returns a formatted display string for the discount
  static String getDiscountDisplayText({
    required String discountType,
    required double discountValue,
    String currencySymbol = '₹',
  }) {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%';
    } else {
      return '$currencySymbol${discountValue.toStringAsFixed(0)}';
    }
  }
  
  /// Get the final price after applying a discount, safely handling various data types
  /// 
  /// Parameters:
  /// - [originalPrice]: Original price of the product
  /// - [discountType]: Type of discount ('percentage' or 'flat')
  /// - [discountValue]: Value of the discount (can be int, double, or String)
  /// - [currencySymbol]: Optional currency symbol for formatted output
  /// - [formatOutput]: Whether to format the output as a display string with currency symbol
  /// 
  /// Returns either the discounted price as a double or a formatted string with currency symbol
  static dynamic getDiscountedPrice({
    required double originalPrice,
    required String? discountType,
    required dynamic discountValue,
    String currencySymbol = '₹',
    bool formatOutput = false,
  }) {
    // Convert discount value to double
    double? discountValueDouble;
    
    if (discountValue == null) {
      discountValueDouble = null;
    } else if (discountValue is int) {
      discountValueDouble = discountValue.toDouble();
    } else if (discountValue is double) {
      discountValueDouble = discountValue;
    } else if (discountValue is String) {
      discountValueDouble = double.tryParse(discountValue);
    }

    
    
    // Calculate final price
    double finalPrice = calculateFinalPrice(
      originalPrice: originalPrice,
      discountType: discountType,
      discountValue: discountValueDouble,
    );
    
    // Ensure price is never negative
    finalPrice = finalPrice < 0 ? 0 : finalPrice;
    
    // Return formatted string or raw value
    return formatOutput 
        ? '$currencySymbol${finalPrice.toStringAsFixed(0)}' 
        : finalPrice;
  }
  
  /// Process a discount info map to extract the final price
  /// Useful when working with discount info retrieved from Firestore
  /// 
  /// Parameters:
  /// - [discountInfo]: Map containing discount information
  /// - [originalPrice]: Original price to use if discount info doesn't contain a final price
  /// - [currencySymbol]: Optional currency symbol for formatted output
  /// - [formatOutput]: Whether to return a formatted string with currency symbol
  /// 
  /// Returns the final price after discount as a double or formatted string
  static dynamic getFinalPriceFromDiscountInfo({
    required Map<String, dynamic>? discountInfo,
    required double originalPrice,
    String currencySymbol = '₹',
    bool formatOutput = false,
  }) {
    // If no discount info or not a valid discount, return original price
    if (discountInfo == null || discountInfo['hasDiscount'] != true) {
      return formatOutput 
          ? '$currencySymbol${originalPrice.toStringAsFixed(0)}' 
          : originalPrice;
    }
    
    // Try to get final price directly from discount info
    var finalPrice = discountInfo['finalPrice'];
    double finalPriceDouble;
    
    if (finalPrice is int) {
      finalPriceDouble = finalPrice.toDouble();
    } else if (finalPrice is double) {
      finalPriceDouble = finalPrice;
    } else if (finalPrice is String && double.tryParse(finalPrice) != null) {
      finalPriceDouble = double.parse(finalPrice);
    } else {
      // Calculate price using discount type and value if final price not available
      finalPriceDouble = getDiscountedPrice(
        originalPrice: originalPrice,
        discountType: discountInfo['discountType'],
        discountValue: discountInfo['discountValue'],
      );
    }
    
    // Ensure price is never negative
    finalPriceDouble = finalPriceDouble < 0 ? 0 : finalPriceDouble;
    
    // Return formatted string or raw value
    return formatOutput 
        ? '$currencySymbol${finalPriceDouble.toStringAsFixed(0)}' 
        : finalPriceDouble;
  }
  
  /// Log discount information for a product
  /// This prints discount type, value and product ID
  static void logDiscount({
    required String productId, 
    String? discountType, 
    double? discountValue
  }) {
    final hasDisc = discountType != null && discountValue != null && discountValue > 0;
    final discText = hasDisc 
        ? "${discountType == 'percentage' ? '$discountValue%' : '₹$discountValue'}"
        : "No discount";
    
    print("DISCOUNT: Product $productId - Type: ${discountType ?? 'None'}, Value: $discText");
  }
  
  /// Get complete discount information for a product by its ID directly from Firestore
  /// Checks if an entry with the same ID exists in the discounts collection
  static Future<Map<String, dynamic>> getProductDiscountInfo(String productId) async {
    // Check if we have cached discount info
    if (_discountCache.containsKey(productId)) {
      return _discountCache[productId]!;
    }
    
    try {
      // Get Firebase instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // First, check if there's a discount entry for this product in the discounts collection
      final discountDoc = await firestore.collection('discounts').doc(productId).get();
      
      if (discountDoc.exists) {
        // We found a discount record for this product
        final discountData = discountDoc.data() as Map<String, dynamic>;
        
        // Get product info to calculate final price
        final productService = GetIt.instance<SharedProductService>();
        final product = await productService.getProductById(productId);
        
        if (product == null) {
          return {'hasDiscount': false, 'error': 'Product not found'};
        }
        
        // Extract discount details
        final String discountType = discountData['discountType'] ?? 'percentage';
        final double discountValue = (discountData['discountValue'] is int)
            ? (discountData['discountValue'] as int).toDouble()
            : (discountData['discountValue'] as double? ?? 0);
        
        // Calculate prices
        final originalPrice = product.mrp ?? product.price;
        final finalPrice = calculateFinalPrice(
          originalPrice: originalPrice,
          discountType: discountType,
          discountValue: discountValue,
        );
        
        // Calculate discount percentage
        final discountPercentage = calculateDiscountPercentage(
          originalPrice: originalPrice,
          finalPrice: finalPrice,
        );
        
        // Prepare the discount info
        final discountInfo = {
          'productId': productId,
          'productName': product.name,
          'originalPrice': originalPrice,
          'finalPrice': finalPrice,
          'hasDiscount': true,
          'discountType': discountType,
          'discountValue': discountValue,
          'discountPercentage': discountPercentage,
          'startDate': discountData['startDate'],
          'endDate': discountData['endDate'],
          'isActive': discountData['isActive'] ?? true,
        };
        
        // Cache for future use
        _discountCache[productId] = discountInfo;
        
        // Log the discount info
        logDiscount(
          productId: productId,
          discountType: discountType,
          discountValue: discountValue,
        );
        
        return discountInfo;
      } else {
        // No discount entry found for this product
        // Get basic product info for the response
        final productService = GetIt.instance<SharedProductService>();
        final product = await productService.getProductById(productId);
        
        if (product == null) {
          return {'hasDiscount': false, 'error': 'Product not found'};
        }
        
        // Prepare response with no discount
        final noDiscountInfo = {
          'productId': productId,
          'productName': product.name,
          'originalPrice': product.mrp ?? product.price,
          'finalPrice': product.price,
          'hasDiscount': false,
          'discountPercentage': 0,
          'discountAmount': 0,
        };
        
        // Cache for future use
        _discountCache[productId] = noDiscountInfo;
        
        return noDiscountInfo;
      }
    } catch (e) {
      print('Error getting product discount info from Firestore: $e');
      return {'hasDiscount': false, 'error': e.toString()};
    }
  }
  
  /// Get discount information synchronously (from cache only)
  /// Returns null if not in cache
  static Map<String, dynamic>? getCachedDiscountInfo(String productId) {
    return _discountCache[productId];
  }
  
  /// Get discount information for multiple products at once
  /// Returns a map where keys are product IDs and values are their discount information
  static Future<Map<String, Map<String, dynamic>>> getBatchProductDiscountInfo(List<String> productIds) async {
    Map<String, Map<String, dynamic>> results = {};
    
    try {
      // Get Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get all discounts from the discounts collection that match the product IDs
      final QuerySnapshot discountsQuery = await firestore
          .collection('discounts')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();
      
      // Convert to map for easier lookup
      Map<String, Map<String, dynamic>> discountsMap = {};
      for (var doc in discountsQuery.docs) {
        discountsMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
      
      // Get product service for fetching product details
      final productService = GetIt.instance<SharedProductService>();
      
      // Process each product ID
      for (String productId in productIds) {
        // Check if we have cached discount info
        if (_discountCache.containsKey(productId)) {
          results[productId] = _discountCache[productId]!;
          continue;
        }
        
        try {
          // Get product details
          final product = await productService.getProductById(productId);
          
          if (product == null) {
            results[productId] = {'hasDiscount': false, 'error': 'Product not found'};
            continue;
          }
          
          // Check if we have a discount for this product
          if (discountsMap.containsKey(productId)) {
            final discountData = discountsMap[productId]!;
            
            // Extract discount details
            final String discountType = discountData['discountType'] ?? 'percentage';
            final double discountValue = (discountData['discountValue'] is int)
                ? (discountData['discountValue'] as int).toDouble()
                : (discountData['discountValue'] as double? ?? 0);
            
            // Calculate prices
            final originalPrice = product.mrp ?? product.price;
            final finalPrice = calculateFinalPrice(
              originalPrice: originalPrice,
              discountType: discountType,
              discountValue: discountValue,
            );
            
            // Calculate discount percentage
            final discountPercentage = calculateDiscountPercentage(
              originalPrice: originalPrice,
              finalPrice: finalPrice,
            );
            
            // Prepare the discount info
            final discountInfo = {
              'productId': productId,
              'productName': product.name,
              'originalPrice': originalPrice,
              'finalPrice': finalPrice,
              'hasDiscount': true,
              'discountType': discountType,
              'discountValue': discountValue,
              'discountPercentage': discountPercentage,
              'startDate': discountData['startDate'],
              'endDate': discountData['endDate'],
              'isActive': discountData['isActive'] ?? true,
            };
            
            // Cache for future use
            _discountCache[productId] = discountInfo;
            
            // Add to results
            results[productId] = discountInfo;
            
            // Log the discount
            logDiscount(
              productId: productId,
              discountType: discountType,
              discountValue: discountValue,
            );
          } else {
            // No discount for this product
            final noDiscountInfo = {
              'productId': productId,
              'productName': product.name,
              'originalPrice': product.mrp ?? product.price,
              'finalPrice': product.price,
              'hasDiscount': false,
              'discountPercentage': 0,
              'discountAmount': 0,
            };
            
            // Cache for future use
            _discountCache[productId] = noDiscountInfo;
            
            // Add to results
            results[productId] = noDiscountInfo;
          }
        } catch (e) {
          print('Error processing product $productId: $e');
          results[productId] = {'hasDiscount': false, 'error': e.toString()};
        }
      }
      
      return results;
    } catch (e) {
      print('Error in batch discount info: $e');
      // Return an empty map with error for all requested products
      for (String productId in productIds) {
        results[productId] = {'hasDiscount': false, 'error': e.toString()};
      }
      return results;
    }
  }
} 