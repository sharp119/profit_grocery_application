import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../domain/entities/product.dart';
import '../../../core/utils/color_mapper.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
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
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Use cart quantities from CartBloc state or the passed cartQuantities
        Map<String, int> quantities = {};
        
        // First try to use quantities from the passed cartQuantities
        if (cartQuantities != null) {
          quantities = cartQuantities!;
        }
        
        // If CartBloc is loaded, use its quantities (which may be more up-to-date)
        if (cartState.status == CartStatus.loaded) {
          // Create a map of product IDs to quantities
          for (final item in cartState.items) {
            quantities[item.productId] = item.quantity;
          }
        }
        
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            
            // Get quantity from cart
            final quantity = quantities[product.id] ?? 0;
            
            // Get background color for product
            Color backgroundColor = ColorMapper.getColorForCategory(
              product.subcategoryId ?? product.categoryId,
              fallbackColors: subCategoryColors,
            );
            
            return EnhancedProductCard.fromEntity(
              product: product,
              onTap: () => onProductTap(product),
              onQuantityChanged: (qty) => onQuantityChanged(product, qty),
              quantity: quantity,
              backgroundColor: backgroundColor,
              showAddButton: showAddButton,
            );
          },
        );
      },
    );
  }
}
