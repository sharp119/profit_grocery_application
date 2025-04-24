import 'package:flutter/material.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../services/logging_service.dart';
import 'reusable_product_card.dart';

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

    // Calculate original price to show (either MRP or regular price depending on discount type)
    final originalPrice = product.mrp != null && product.mrp! > bestsellerProduct.finalPrice 
        ? product.mrp 
        : bestsellerProduct.hasSpecialDiscount 
            ? product.price 
            : null;

    // Use the reusable product card with bestseller-specific data
    return ReusableProductCard(
      product: product,
      finalPrice: bestsellerProduct.finalPrice,
      originalPrice: originalPrice,
      hasDiscount: bestsellerProduct.hasSpecialDiscount,
      discountType: bestsellerProduct.discountType,
      discountValue: bestsellerProduct.discountValue,
      backgroundColor: backgroundColor,
      onTap: _handleTap,
      // onQuantityChanged: _handleQuantityChanged,
      // quantity: quantity,
    );
  }
}