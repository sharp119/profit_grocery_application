import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart.dart';
import '../cards/product_card.dart';

/// A reusable grid view for displaying product cards
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product, int) onQuantityChanged;
  final Map<String, int> cartQuantities; // Map of product ID to quantity in cart
  final int crossAxisCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities = const {},
    this.crossAxisCount = 2,
    this.shrinkWrap = true,
    this.physics,
    this.padding,
  }) : super(key: key);

  /// Create a ProductGrid with cart information
  factory ProductGrid.withCart({
    required List<Product> products,
    required Cart cart,
    required Function(Product) onProductTap,
    required Function(Product, int) onQuantityChanged,
    int crossAxisCount = 2,
    bool shrinkWrap = true,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    // Create a map of product IDs to quantities from the cart
    final cartQuantities = <String, int>{};
    for (final item in cart.items) {
      cartQuantities[item.productId] = item.quantity;
    }

    return ProductGrid(
      products: products,
      onProductTap: onProductTap,
      onQuantityChanged: onQuantityChanged,
      cartQuantities: cartQuantities,
      crossAxisCount: crossAxisCount,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.7, // Adjust based on your card design
      ),
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final quantity = cartQuantities[product.id] ?? 0;
        
        return ProductCard.fromEntity(
          product: product,
          onTap: () => onProductTap(product),
          onQuantityChanged: (newQuantity) => onQuantityChanged(product, newQuantity),
          quantity: quantity,
        );
      },
    );
  }
}