import 'package:flutter/material.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../services/logging_service.dart';
import '../../../services/discount/discount_service.dart';
import 'reusable_product_card.dart';

/**
 * BestsellerProductCard
 * 
 * A specialized product card for bestseller products that uses the ReusableProductCard component.
 * This card is specifically designed for the bestseller section in the home screen.
 * 
 * Usage:
 * - Used in SimpleBestsellerGrid for displaying bestseller products
 * - Shows special bestseller discounts (percentage or flat)
 * - Displays bestseller badge
 * - Handles cart quantity changes
 * 
 * Key Features:
 * - Special bestseller pricing and discounts
 * - Rank information
 * - Bestseller badge
 * - Cart functionality
 * 
 * Where Used:
 * - Home Screen: SimpleBestsellerGrid (12 bestsellers in 2-column grid)
 * - Bestseller Collections: Shows special discounts and badges
 * - Featured Sections: When highlighting bestseller products
 * 
 * Example Usage:
 * ```dart
 * BestsellerProductCard(
 *   bestsellerProduct: bestsellerProduct,
 *   backgroundColor: categoryColor,
 *   onTap: (product) => navigateToDetails(product),
 *   onQuantityChanged: (product, qty) => updateCart(product, qty),
 *   quantity: cartQuantities[product.id] ?? 0,
 * )
 * ```
 */

/// A specialized product card for bestseller products
/// Uses the reusable product card component
class BestsellerProductCard extends StatelessWidget {
  final BestsellerProduct bestsellerProduct;
  final Color backgroundColor;
  final Function(BestsellerProduct)? onTap;
  final Function(BestsellerProduct, int)? onQuantityChanged;
  final int quantity;
  final bool showBestsellerBadge; // Kept for backward compatibility

  const BestsellerProductCard({
    Key? key,
    required this.bestsellerProduct,
    required this.backgroundColor,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.showBestsellerBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = bestsellerProduct.product;
    
    // Log the bestseller-specific info
    LoggingService.logFirestore(
      'BESTSELLER_CARD: Using bestseller product ${product.name} with rank ${bestsellerProduct.rank}'
    );

    // Handle callbacks by wrapping them to pass BestsellerProduct instead of Product
    void _handleTap(dynamic _) {
      if (onTap != null) {
        onTap!(bestsellerProduct);
      }
    }

    void _handleQuantityChanged(dynamic _, int newQuantity) {
      if (onQuantityChanged != null) {
        onQuantityChanged!(bestsellerProduct, newQuantity);
      }
    }

    // Use DiscountService to determine discount properties
    final hasDiscount = DiscountService.hasDiscount(
      discountType: bestsellerProduct.discountType,
      discountValue: bestsellerProduct.discountValue,
    );
    
    // Calculate original price to show (either MRP or regular price depending on discount type)
    final originalPrice = product.mrp != null && product.mrp! > bestsellerProduct.finalPrice 
        ? product.mrp 
        : hasDiscount 
            ? product.price 
            : null;

    // Use the reusable product card with bestseller-specific data
    return ReusableProductCard(
      product: product,
      finalPrice: bestsellerProduct.finalPrice,
      originalPrice: originalPrice,
      hasDiscount: hasDiscount,
      discountType: bestsellerProduct.discountType,
      discountValue: bestsellerProduct.discountValue,
      backgroundColor: backgroundColor,
      onTap: _handleTap,
      // onQuantityChanged: _handleQuantityChanged,
      // quantity: quantity,
    );
  }
}