import 'package:flutter/material.dart';
import '../../../domain/entities/product.dart';
import 'reusable_product_card.dart';

/**
 * StandardProductCard
 * 
 * A standard product card used for regular product displays throughout the app.
 * This card extends the ReusableProductCard with standard product display functionality.
 * 
 * Usage:
 * - Used in regular product listings and category pages
 * - Handles standard product discounts (percentage or flat)
 * - Provides consistent product display across non-specialized sections
 * 
 * Key Features:
 * - Standard product display
 * - Discount handling (percentage or flat)
 * - Cart quantity management
 * - Consistent with app theme
 * 
 * Where Used:
 * - Regular Product Listings: Standard product display
 * - Category Pages: Consistent product presentation
 * - General Product Grids: When no special features are needed
 * - Basic Product Collections: Standard product showcase
 * 
 * Example Usage:
 * ```dart
 * StandardProductCard(
 *   product: product,
 *   backgroundColor: categoryColor,
 *   discountPercentage: 10.0, // Optional percentage discount
 *   flatDiscount: 20.0, // Optional flat discount
 *   onTap: (product) => navigateToDetails(product),
 *   onQuantityChanged: (product, qty) => updateCart(product, qty),
 *   quantity: cartQuantities[product.id] ?? 0,
 * )
 * ```
 */

/// A standard product card used for regular product displays
/// Uses the reusable product card component
class StandardProductCard extends StatelessWidget {
  final Product product;
  final Color backgroundColor;
  final double? discountPercentage;
  final double? flatDiscount;
  final Function(Product)? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;

  const StandardProductCard({
    Key? key,
    required this.product,
    required this.backgroundColor,
    this.discountPercentage,
    this.flatDiscount,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate final price based on discounts
    final originalPrice = product.mrp ?? product.price;
    double finalPrice = product.price;
    
    // Determine discount type and value
    String? discountType;
    double? discountValue;
    bool hasDiscount = false;
    
    if (discountPercentage != null && discountPercentage! > 0) {
      // Percentage discount
      discountType = 'percentage';
      discountValue = discountPercentage;
      finalPrice = originalPrice - (originalPrice * discountPercentage! / 100);
      hasDiscount = true;
    } else if (flatDiscount != null && flatDiscount! > 0) {
      // Flat discount
      discountType = 'flat';
      discountValue = flatDiscount;
      finalPrice = originalPrice - flatDiscount!;
      hasDiscount = true;
    }
    
    // Ensure final price is not negative
    finalPrice = finalPrice < 0 ? 0 : finalPrice;

    // Use the reusable product card
    return ReusableProductCard(
      product: product,
      finalPrice: finalPrice,
      originalPrice: hasDiscount ? originalPrice : null,
      hasDiscount: hasDiscount,
      discountType: discountType,
      discountValue: discountValue,
      backgroundColor: backgroundColor,
      onTap: onTap,
      // onQuantityChanged: onQuantityChanged,
      // quantity: quantity,
    );
  }
}