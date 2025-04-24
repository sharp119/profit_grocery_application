import 'package:flutter/material.dart';
import '../../../domain/entities/product.dart';
import '../cards/improved_product_card.dart';
import '../cards/reusable_product_card.dart';
import '../cards/standard_product_card.dart';

/// A factory that decides which product card to use
/// This allows us to gradually migrate to the improved card system
/// without breaking existing code
class ProductCardFactory {
  /// Create a product card based on the current app configuration
  /// 
  /// - If useImprovedCards is true, it returns the improved product card
  /// - Otherwise, it falls back to the standard card
  static Widget createProductCard({
    required Product product,
    required Color backgroundColor,
    double? discountPercentage,
    double? flatDiscount,
    Function(Product)? onTap,
    Function(Product, int)? onQuantityChanged,
    int quantity = 0,
    bool useImprovedCards = true,  // Set to true to use the improved cards
  }) {
    if (useImprovedCards) {
      // Calculate final price based on discounts
      final originalPrice = product.mrp ?? product.price;
      double finalPrice = product.price;
      
      // Determine discount type and value
      String? discountType;
      double? discountValue;
      bool hasDiscount = false;
      
      if (discountPercentage != null && discountPercentage > 0) {
        // Percentage discount
        discountType = 'percentage';
        discountValue = discountPercentage;
        finalPrice = originalPrice - (originalPrice * discountPercentage / 100);
        hasDiscount = true;
      } else if (flatDiscount != null && flatDiscount > 0) {
        // Flat discount
        discountType = 'flat';
        discountValue = flatDiscount;
        finalPrice = originalPrice - flatDiscount;
        hasDiscount = true;
      }
      
      // Ensure final price is not negative
      finalPrice = finalPrice < 0 ? 0 : finalPrice;
      
      // Return the improved product card
      return ImprovedProductCard(
        product: product,
        finalPrice: finalPrice,
        originalPrice: hasDiscount ? originalPrice : null,
        hasDiscount: hasDiscount,
        discountType: discountType,
        discountValue: discountValue,
        backgroundColor: backgroundColor,
        onTap: onTap,
      );
    } else {
      // Fall back to the standard card for backward compatibility
      return StandardProductCard(
        product: product,
        backgroundColor: backgroundColor,
        discountPercentage: discountPercentage,
        flatDiscount: flatDiscount,
        onTap: onTap,
        onQuantityChanged: onQuantityChanged,
        quantity: quantity,
      );
    }
  }
}