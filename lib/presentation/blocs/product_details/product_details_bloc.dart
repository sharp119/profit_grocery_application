import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/inventory/bestseller_products.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/category_group_model.dart';
import '../../../domain/entities/product.dart';
import 'product_details_event.dart';
import 'product_details_state.dart';

class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  // In a real app, we would inject repository dependencies here
  // final ProductRepository _productRepository;
  // final CartRepository _cartRepository;

  ProductDetailsBloc() : super(const ProductDetailsState()) {
    on<LoadProductDetails>(_onLoadProductDetails);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<ProductDetailsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductDetailsStatus.loading));

      // In a real app, we would fetch the product from a repository
      // For now, we'll use mock data
      final product = await _getMockProduct(event.productId);
      
      // Generate subcategory colors
      final Map<String, Color> subcategoryColors = _generateSubcategoryColors();
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (product != null) {
        emit(state.copyWith(
          status: ProductDetailsStatus.loaded,
          product: product,
          cartItemCount: 2, // Mock cart count
          cartTotalAmount: 350.0, // Mock cart total
          subcategoryColors: subcategoryColors,
        ));
      } else {
        emit(state.copyWith(
          status: ProductDetailsStatus.error,
          errorMessage: 'Product not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProductDetailsStatus.error,
        errorMessage: 'Failed to load product details: $e',
      ));
    }
  }

  void _onAddToCart(
    AddToCart event,
    Emitter<ProductDetailsState> emit,
  ) {
    try {
      // In a real app, we would update the cart in a repository
      // For now, we'll update the state directly
      final product = event.product;
      final quantity = event.quantity;
      
      // Update cart quantities
      final updatedCartQuantities = Map<String, int>.from(state.cartQuantities);
      updatedCartQuantities[product.id] = (updatedCartQuantities[product.id] ?? 0) + quantity;
      
      // Calculate new cart total and count
      final cartItemCount = updatedCartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
      
      // Safely calculate cart total with error handling
      double cartTotalAmount;
      try {
        cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
      } catch (e) {
        // If calculation fails, use a default total based on product price
        cartTotalAmount = product.price * quantity;
      }
      
      emit(state.copyWith(
        cartQuantities: updatedCartQuantities,
        cartItemCount: cartItemCount,
        cartTotalAmount: cartTotalAmount,
      ));
    } catch (e) {
      // Don't show the full exception message to the user
      emit(state.copyWith(
        status: ProductDetailsStatus.error,
        errorMessage: 'Unable to add product to cart',
      ));
    }
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<ProductDetailsState> emit,
  ) {
    try {
      // In a real app, we would update the cart in a repository
      // For now, we'll update the state directly
      final productId = event.productId;
      
      // Update cart quantities
      final updatedCartQuantities = Map<String, int>.from(state.cartQuantities);
      updatedCartQuantities.remove(productId);
      
      // Calculate new cart total and count
      final cartItemCount = updatedCartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
      final cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
      
      emit(state.copyWith(
        cartQuantities: updatedCartQuantities,
        cartItemCount: cartItemCount,
        cartTotalAmount: cartTotalAmount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductDetailsStatus.error,
        errorMessage: 'Failed to remove from cart: $e',
      ));
    }
  }
  
  // Calculate total cart value
  double _calculateCartTotal(Map<String, int> cartQuantities) {
    double total = 0.0;
    
    // In a real app, we'd use a repository to get product prices
    // For mock data, we'll use fixed prices
    cartQuantities.forEach((productId, quantity) {
      // Extract numeric value from product ID or use a default price
      double price = 50.0; // Default price
      
      try {
        if (productId.contains('_')) {
          // If ID has format like "category_subcategory_123", extract the number at the end
          final parts = productId.split('_');
          if (parts.isNotEmpty) {
            final lastPart = parts.last;
            if (int.tryParse(lastPart) != null) {
              price = int.parse(lastPart) * 50.0;
            }
          }
        } else if (int.tryParse(productId) != null) {
          // If ID is a simple number
          price = int.parse(productId) * 50.0;
        }
      } catch (e) {
        // If any error occurs, use the default price
        price = 50.0;
      }
      
      total += price * quantity;
    });
    
    return total;
  }
  
  // Generate subcategory colors
  Map<String, Color> _generateSubcategoryColors() {
    // Use the centralized color definitions from BestsellerProducts
    final Map<String, Color> colors = Map.from(BestsellerProducts.subcategoryColors);
    
    // Add legacy category mappings
    colors['category_1'] = const Color(0xFF1A5D1A); // Dark green
    colors['category_2'] = const Color(0xFFE5BEEC); // Light lavender
    colors['category_3'] = const Color(0xFFECB159); // Yellow/orange
    colors['category_4'] = const Color(0xFF219C90); // Teal
    
    // Map grocery & kitchen categories
    colors['grocery_1'] = colors['vegetables_fruits']!;
    colors['grocery_2'] = colors['atta_rice_dal']!;
    colors['grocery_3'] = colors['oil_ghee_masala']!;
    colors['grocery_4'] = const Color(0xFFE5BEEC); // Light lavender for dairy
    
    colors['kitchen_1'] = const Color(0xFFA9907E); // Brown for bakery
    colors['kitchen_2'] = colors['dry_fruits_cereals']!;
    colors['kitchen_3'] = const Color(0xFF675D50); // Dark brown for meat
    colors['kitchen_4'] = colors['kitchenware']!;
    
    // Map snacks categories
    colors['snacks_1'] = colors['chips_namkeen']!;
    colors['snacks_2'] = colors['sweets_chocolates']!;
    colors['snacks_3'] = colors['drinks_juices']!;
    colors['snacks_4'] = colors['tea_coffee_milk']!;
    colors['snacks_5'] = colors['instant_food']!;
    colors['snacks_6'] = colors['sauces_spreads']!;
    colors['snacks_7'] = colors['paan_corner']!;
    colors['snacks_8'] = colors['ice_cream']!;
    
    // Product ID to category mapping for mock products
    colors['1'] = colors['category_1']!; // Green
    colors['2'] = colors['category_2']!; // Light lavender
    colors['3'] = colors['category_3']!; // Yellow/orange
    colors['4'] = colors['category_4']!; // Teal
    colors['5'] = colors['sauces_spreads']!; // Burgundy
    colors['6'] = colors['vegetables_fruits']!; // Green
    colors['7'] = colors['drinks_juices']!; // Teal
    colors['8'] = colors['chips_namkeen']!; // Yellow/orange
    colors['9'] = colors['kitchen_3']!; // Dark brown
    colors['10'] = colors['kitchen_1']!; // Brown
    colors['11'] = colors['chips_namkeen']!; // Yellow
    colors['12'] = colors['kitchenware']!; // Slate
    
    return colors;
  }
  
  // Mock data methods
  Future<Product?> _getMockProduct(String productId) async {
    // In a real app, we would fetch this from a repository
    // For now, we'll return a product based on the ID
    
    // Try to parse the ID as a number for our mock data
    int? id;
    try {
      id = int.parse(productId);
    } catch (e) {
      // Not a number, use a default
      id = 1;
    }
    
    // Create a mock product
    return Product(
      id: productId,
      name: 'Product $id',
      description: 'This is a detailed description for Product $id. It contains information about the product features, benefits, and usage instructions. The product is made with high-quality materials and is designed to provide the best user experience.',
      image: '${AppConstants.assetsProductsPath}${(id % 6) + 1}.png',
      price: 50.0 * id,
      mrp: 60.0 * id,
      inStock: id % 5 != 0, // Every 5th product is out of stock
      categoryId: 'category_${id % 3 + 1}',
      categoryName: 'Category ${id % 3 + 1}',
      isFeatured: id % 2 == 0,
      weight: '${(id * 100) % 1000}g',
      brand: 'Brand ${id % 5 + 1}',
    );
  }
}