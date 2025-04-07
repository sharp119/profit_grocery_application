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
  final Map<String, Color>? subCategoryColors; // Map of subcategory ID to color

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
    this.subCategoryColors,
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
    Map<String, Color>? subCategoryColors,
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
      subCategoryColors: subCategoryColors,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.64, // Match the ProductCard's new aspect ratio
      ),
      shrinkWrap: shrinkWrap,
      // Don't load all items at once, use caching
      cacheExtent: 500, // Increase the cache extent for smoother scrolling
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      // Limit the number of items displayed to between 8 and 15
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final quantity = cartQuantities[product.id] ?? 0;
        
        // Get the background color based on category ID
        Color? backgroundColor;
        if (subCategoryColors != null && product.categoryId != null) {
          backgroundColor = subCategoryColors?[product.categoryId];
        }
        
        return ProductCard.fromEntity(
          product: product,
          onTap: () => onProductTap(product),
          onQuantityChanged: (newQuantity) => onQuantityChanged(product, newQuantity),
          quantity: quantity,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}