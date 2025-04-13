import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../presentation/blocs/cart/cart_bloc.dart';
import '../../../presentation/blocs/cart/cart_state.dart';
import '../../../presentation/blocs/category_products/category_products_bloc.dart';
import '../../../presentation/blocs/home/home_bloc.dart';
import '../../../presentation/blocs/product_details/product_details_bloc.dart';
import '../../../services/cart/universal/universal_cart_service.dart';
import '../../../utils/cart_logger.dart';
import 'product_card.dart';

/// A wrapper for ProductCard that ensures consistent behavior across all screens
class UniversalProductCard extends StatelessWidget {
  // Product can be provided directly or by ID
  final Product? product;
  final String? productId;
  final VoidCallback onTap;
  final int quantity;
  final Color? backgroundColor;
  final bool useBackgroundColor;

  const UniversalProductCard({
    Key? key,
    this.product,
    this.productId,
    required this.onTap,
    this.quantity = 0,
    this.backgroundColor,
    this.useBackgroundColor = true,
  }) : assert(product != null || productId != null, "Either product or productId must be provided"),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the centralized cart service
    final cartService = UniversalCartService();
    
    // If we have a product ID but no product, get the product from inventory
    final Product displayProduct;
    if (product != null) {
      displayProduct = product!;
    } else {
      // Get product from inventory
      final fetchedProduct = cartService.getProductById(productId!);
      if (fetchedProduct == null) {
        return const SizedBox.shrink(); // Product not found
      }
      displayProduct = fetchedProduct;
    }
    
    // Determine background color
    Color? cardBackgroundColor;
    if (useBackgroundColor) {
      // Use the provided backgroundColor or get from product's category
      cardBackgroundColor = backgroundColor ?? cartService.getBackgroundColorForProduct(displayProduct);
    }
    
    // Handle quantity changes
    void handleQuantityChanged(int newQuantity) {
      try {
        // Get the relevant BLoCs from context if available
        HomeBloc? homeBloc;
        CategoryProductsBloc? categoryProductsBloc;
        ProductDetailsBloc? productDetailsBloc;
        
        try { homeBloc = BlocProvider.of<HomeBloc>(context); } catch (_) {}
        try { categoryProductsBloc = BlocProvider.of<CategoryProductsBloc>(context); } catch (_) {}
        try { productDetailsBloc = BlocProvider.of<ProductDetailsBloc>(context); } catch (_) {}
        
        // Use the centralized cart service for consistent behavior
        cartService.updateCartQuantity(
          product: displayProduct,
          quantity: newQuantity,
          context: context,
          homeBloc: homeBloc,
          categoryProductsBloc: categoryProductsBloc,
          productDetailsBloc: productDetailsBloc,
        );
      } catch (e) {
        CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Error handling quantity change', e);
      }
    }
    
    // Get the current quantity from CartBloc if available
    int currentQuantity = quantity; // Default to the provided quantity
    
    try {
      final cartBloc = BlocProvider.of<CartBloc>(context);
      final cartState = cartBloc.state;
      
      if (cartState.status == CartStatus.loaded) {
        // Look for this product in the current cart
        final cartItem = cartState.items.where((item) => item.productId == displayProduct.id).toList();
        if (cartItem.isNotEmpty) {
          // Found in cart, use the quantity from cart
          currentQuantity = cartItem.first.quantity;
        }
      }
    } catch (e) {
      // CartBloc not available, continue with provided quantity
      CartLogger.info('UNIVERSAL_PRODUCT_CARD', 'CartBloc not available, using provided quantity: $quantity');
    }
    
    // Return the ProductCard with consistent behavior
    return ProductCard.fromEntity(
      product: displayProduct,
      onTap: onTap,
      onQuantityChanged: handleQuantityChanged,
      quantity: currentQuantity,
      backgroundColor: cardBackgroundColor,
    );
  }
}