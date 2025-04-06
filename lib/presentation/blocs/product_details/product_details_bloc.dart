import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
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
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (product != null) {
        emit(state.copyWith(
          status: ProductDetailsStatus.loaded,
          product: product,
          cartItemCount: 2, // Mock cart count
          cartTotalAmount: 350.0, // Mock cart total
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
      final cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
      
      emit(state.copyWith(
        cartQuantities: updatedCartQuantities,
        cartItemCount: cartItemCount,
        cartTotalAmount: cartTotalAmount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductDetailsStatus.error,
        errorMessage: 'Failed to add to cart: $e',
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
      // Mock price calculation based on product ID
      final price = double.parse(productId) * 50.0;
      total += price * quantity;
    });
    
    return total;
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