import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart.dart';
import '../cards/universal_product_card.dart';

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
    // If no products, show a clear message
    if (products.isEmpty) {
      return Padding(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        child: Center(
          child: Text(
            'No products available in this category',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.7, // Decreased to provide more vertical space
      ),
      shrinkWrap: shrinkWrap,
      // Don't load all items at once, use caching
      cacheExtent: 500, // Increase the cache extent for smoother scrolling
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      // Display all products for this subcategory
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final quantity = cartQuantities[product.id] ?? 0;
        
        // Get the background color based on product category or ID
        Color? backgroundColor;
        
        // First try using subcategory or category ID with provided colors
        if (subCategoryColors != null) {
          if (product.subcategoryId != null && subCategoryColors!.containsKey(product.subcategoryId)) {
            backgroundColor = subCategoryColors![product.subcategoryId];
          } else if (product.categoryId != null && subCategoryColors!.containsKey(product.categoryId)) {
            backgroundColor = subCategoryColors![product.categoryId];
          } else if (product.id.contains('_')) {
            // Try to extract base category from product ID (e.g., "vegetables_fruits_1")
            final parts = product.id.split('_');
            if (parts.length >= 2) {
              // Try first two parts combined
              final baseCategory = "${parts[0]}_${parts[1]}";
              if (subCategoryColors!.containsKey(baseCategory)) {
                backgroundColor = subCategoryColors![baseCategory];
              } 
              // Try just the first part
              else if (subCategoryColors!.containsKey(parts[0])) {
                backgroundColor = subCategoryColors![parts[0]];
              }
            }
          }
        }
        
        return UniversalProductCard(
          product: product,
          onTap: () => onProductTap(product),
          quantity: quantity,
          backgroundColor: backgroundColor,
          useBackgroundColor: backgroundColor != null,
        );
      },
    );
  }
}