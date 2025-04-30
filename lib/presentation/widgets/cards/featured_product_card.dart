import 'package:flutter/material.dart';
import '../../../domain/entities/product.dart';
import 'reusable_product_card.dart';

/**
 * FeaturedProductCard
 * 
 * A specialized product card for featured products and special promotions.
 * This card extends the ReusableProductCard with featured product functionality.
 * 
 * Usage:
 * - Used in featured sections and special promotions
 * - Displays special promotion types (e.g., "Deal of the Day")
 * - Shows featured discounts
 * - Highlights special offers
 * 
 * Key Features:
 * - Special promotion display
 * - Featured discount handling
 * - Promotion type badge
 * - Enhanced visibility for featured items
 * 
 * Where Used:
 * - Featured Sections: Highlighting special products
 * - Deal of the Day: Special promotion display
 * - Limited Time Offers: Time-sensitive promotions
 * - Premium Product Showcases: For featured items
 * 
 * Example Usage:
 * ```dart
 * FeaturedProductCard(
 *   product: product,
 *   backgroundColor: categoryColor,
 *   promotionType: "Deal of the Day",
 *   discountPercentage: 20.0,
 *   onTap: (product) => navigateToDetails(product),
 *   onQuantityChanged: (product, qty) => updateCart(product, qty),
 *   quantity: cartQuantities[product.id] ?? 0,
 * )
 * ```
 */

/// A featured product card for special promotions or deals
/// Uses the reusable product card component
class FeaturedProductCard extends StatelessWidget {
  final Product product;
  final Color backgroundColor;
  final String? promotionType; // e.g., "Deal of the Day", "Limited Offer"
  final double discountPercentage;
  final Function(Product)? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;

  const FeaturedProductCard({
    Key? key,
    required this.product,
    required this.backgroundColor,
    this.promotionType,
    required this.discountPercentage,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the featured discount
    final originalPrice = product.mrp ?? product.price;
    final finalPrice = originalPrice - (originalPrice * discountPercentage / 100);
    
    // Special logger message for featured products could be added here
    
    // Use the reusable product card with featured-specific data
    return ReusableProductCard(
      product: product,
      finalPrice: finalPrice,
      originalPrice: originalPrice,
      hasDiscount: true,
      discountType: 'percentage',
      discountValue: discountPercentage,
      backgroundColor: backgroundColor,
      onTap: onTap,
      // onQuantityChanged: onQuantityChanged,
      // quantity: quantity,
    );
  }
}