import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../domain/entities/product.dart';
import '../../../core/utils/color_mapper.dart';
import '../cards/enhanced_product_card.dart';

/// A grid view that displays products from Firebase
class FirebaseProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product, int) onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int crossAxisCount;
  final bool showAddButton;
  final double? childAspectRatio;
  final Map<String, Color>? subCategoryColors;
  
  const FirebaseProductGrid({
    Key? key,
    required this.products,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities,
    this.crossAxisCount = 2,
    this.showAddButton = true,
    this.childAspectRatio,
    this.subCategoryColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on available width and desired column count
        final maxWidth = constraints.maxWidth;
        final horizontalPadding = 16.w * 2; // Left and right padding
        final spacing = 16.w * (crossAxisCount - 1); // Total spacing between items
        final availableWidth = maxWidth - horizontalPadding - spacing;
        final itemWidth = availableWidth / crossAxisCount;
        
        // Use cart quantities if passed
        final quantities = cartQuantities ?? <String, int>{};
        
        // Use GridView.builder instead of MasonryGridView for more predictable layout
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            // Use fixed height ratio to ensure consistent sizing
            childAspectRatio: childAspectRatio ?? 0.65, // Height is ~1.5x width
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            
            // Get quantity from cart
            final quantity = quantities[product.id] ?? 0;
            
            // Get background color for product
            final backgroundColor = ColorMapper.getColorForCategory(
              product.subcategoryId ?? product.categoryId,
              // fallbackColors: subCategoryColors,
            );
            
            // Each grid cell has fixed dimensions from the GridView
            return EnhancedProductCard.fromEntity(
              product: product,
              onTap: () => onProductTap(product),
              onQuantityChanged: (newQuantity) => onQuantityChanged(product, newQuantity),
              quantity: quantity,
              backgroundColor: backgroundColor,
              // showAddButton: showAddButton,
            );
          },
        );
      },
    );
  }
}