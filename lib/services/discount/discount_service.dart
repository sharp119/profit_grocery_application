import 'package:flutter/material.dart';

/// Service for handling product discount calculations and related operations
/// This centralized service ensures consistent discount handling across different product cards
class DiscountService {
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
} 