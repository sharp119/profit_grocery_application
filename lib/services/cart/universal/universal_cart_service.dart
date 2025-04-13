import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/inventory/product_inventory.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/product.dart';
import '../../../presentation/blocs/cart/cart_bloc.dart';
import '../../../presentation/blocs/cart/cart_event.dart' as cart_events;
import '../../../presentation/blocs/category_products/category_products_bloc.dart';
import '../../../presentation/blocs/home/home_bloc.dart';
import '../../../presentation/blocs/home/home_event.dart' as home_events;
import '../../../presentation/blocs/product_details/product_details_bloc.dart';
import '../../../presentation/blocs/product_details/product_details_event.dart' as product_events;
import '../../../services/user_service_interface.dart';
import '../../../utils/cart_logger.dart';
import '../home_cart_bridge.dart';

/// UniversalCartService - A centralized service for all cart operations
/// This service ensures consistent behavior across all screens
class UniversalCartService {
  // Singleton pattern implementation
  static final UniversalCartService _instance = UniversalCartService._internal();
  
  factory UniversalCartService() {
    return _instance;
  }
  
  UniversalCartService._internal();
  
  // Method to update a product's quantity in cart
  Future<void> updateCartQuantity({
    required Product product,
    required int quantity,
    required BuildContext context,
    HomeBloc? homeBloc,
    CategoryProductsBloc? categoryProductsBloc,
    ProductDetailsBloc? productDetailsBloc,
  }) async {
    CartLogger.log('UNIVERSAL_CART', 'Updating cart quantity for: ${product.name}, quantity: $quantity');
    
    // STEP 1: Add to Firebase Realtime Database (should work regardless of context)
    await _logToFirebaseRTDB(product, quantity);
    
    // STEP 2: Update CartBloc if available in context
    try {
      final cartBloc = _getCartBlocFromContext(context);
      if (cartBloc != null) {
        if (quantity <= 0) {
          cartBloc.add(cart_events.RemoveFromCart(product.id));
          CartLogger.info('UNIVERSAL_CART', 'Removed product from CartBloc: ${product.id}');
        } else {
          cartBloc.add(cart_events.AddToCart(product, quantity));
          CartLogger.info('UNIVERSAL_CART', 'Added product to CartBloc: ${product.id}, quantity: $quantity');
        }
      } else {
        CartLogger.info('UNIVERSAL_CART', 'CartBloc not available in context');
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_CART', 'Error updating CartBloc', e);
    }
    
    // STEP 3: Update screen-specific bloc if provided
    
    // For HomeBloc
    if (homeBloc != null) {
      try {
        homeBloc.add(home_events.UpdateCartQuantity(product, quantity));
        CartLogger.info('UNIVERSAL_CART', 'Updated HomeBloc');
      } catch (e) {
        CartLogger.error('UNIVERSAL_CART', 'Error updating HomeBloc', e);
      }
    }
    
    // For CategoryProductsBloc
    if (categoryProductsBloc != null) {
      try {
        // Access the UpdateCartQuantity event class directly
        categoryProductsBloc.add(UpdateCartQuantity(
          product: product,
          quantity: quantity,
        ));
        CartLogger.info('UNIVERSAL_CART', 'Updated CategoryProductsBloc');
      } catch (e) {
        CartLogger.error('UNIVERSAL_CART', 'Error updating CategoryProductsBloc', e);
      }
    }
    
    // For ProductDetailsBloc
    if (productDetailsBloc != null) {
      try {
        if (quantity <= 0) {
          productDetailsBloc.add(product_events.RemoveFromCart(product.id));
        } else {
          productDetailsBloc.add(product_events.AddToCart(product, quantity));
        }
        CartLogger.info('UNIVERSAL_CART', 'Updated ProductDetailsBloc');
      } catch (e) {
        CartLogger.error('UNIVERSAL_CART', 'Error updating ProductDetailsBloc', e);
      }
    }
    
    // STEP 4: Use HomeCartBridge if both HomeBloc and CartBloc are available
    if (homeBloc != null) {
      try {
        final cartBloc = _getCartBlocFromContext(context);
        if (cartBloc != null) {
          final bridge = HomeCartBridge(
            cartBloc: cartBloc,
            homeBloc: homeBloc,
          );
          
          if (quantity <= 0) {
            bridge.removeFromCart(product);
          } else {
            bridge.updateCartItemQuantity(product, quantity);
          }
          CartLogger.info('UNIVERSAL_CART', 'Updated cart via HomeCartBridge');
        }
      } catch (e) {
        CartLogger.error('UNIVERSAL_CART', 'Error using HomeCartBridge', e);
      }
    }
    
    // STEP 5: Show snackbar feedback
    try {
      _showSnackbarFeedback(context, product, quantity);
    } catch (e) {
      CartLogger.error('UNIVERSAL_CART', 'Error showing snackbar', e);
    }
    
    CartLogger.success('UNIVERSAL_CART', 'Completed cart update operation');
  }
  
  // Helper method to log to Firebase Realtime Database
  Future<void> _logToFirebaseRTDB(Product product, int quantity) async {
    try {
      final userId = GetIt.instance<IUserService>().getCurrentUserId();
      if (userId != null) {
        // Create a simple test path specific to this user's cart
        final database = GetIt.instance<FirebaseDatabase>();
        final ref = database.ref().child('carts_test/$userId');
        
        // Create specific message
        String cartMessage = "yoyo product with id ${product.id} got added in the cart";
        
        // Handle the product.price to make sure it's a valid double
        double safePrice = 0.0;
        try {
          safePrice = product.price;
        } catch (e) {
          CartLogger.error('UNIVERSAL_CART', 'Error parsing product price: ${e.toString()}', e);
          // Use a default price if there's an error
          safePrice = 0.0;
        }
        
        // Write entry with specific message, ensuring all values are of the correct type
        await ref.set({
          'product_id': product.id.toString(), // Ensure it's a string
          'product_name': product.name.toString(), // Ensure it's a string
          'quantity': quantity,
          'price': safePrice, // Use the safe price
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'message': cartMessage,
          'test_entry': true
        });
        
        // Log the specific message
        CartLogger.success('UNIVERSAL_CART', cartMessage);
        print('CART TEST: $cartMessage');
      } else {
        CartLogger.info('UNIVERSAL_CART', 'User ID not available for Firebase logging');
      }
    } catch (e) {
      // Handle errors without showing the user
      CartLogger.error('UNIVERSAL_CART', 'Failed to write data to Firebase', e);
      print('Failed to log to Firebase: ${e.toString()}');
    }
  }
  
  // Helper method to show snackbar feedback
  void _showSnackbarFeedback(BuildContext context, Product product, int quantity) {
    try {
      if (quantity > 0) {
        String cartMessage = "Product added to cart successfully";
        
        // Show a snackbar message - don't include product ID as that could be related to the format error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${product.name} added to cart'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Log the error but don't show it to the user
      CartLogger.error('UNIVERSAL_CART', 'Error showing snackbar', e);
      
      // Try to show a simpler message if the normal one fails
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added to cart'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (_) {
        // Ignore if even the simple message fails
      }
    }
  }
  
  // Helper method to get CartBloc from context
  CartBloc? _getCartBlocFromContext(BuildContext context) {
    try {
      return BlocProvider.of<CartBloc>(context);
    } catch (e) {
      return null;
    }
  }
  
  // Get product by ID from inventory
  Product? getProductById(String productId) {
    try {
      final products = ProductInventory.getAllProducts();
      final productModel = products.firstWhere((p) => p.id == productId);
      // Product entity and ProductModel should be compatible
      return productModel;
    } catch (e) {
      CartLogger.error('UNIVERSAL_CART', 'Error fetching product by ID: $productId', e);
      return null;
    }
  }
  
  // Get background color for a product based on category
  Color? getBackgroundColorForProduct(Product product) {
    try {
      // Convert to ProductModel if needed
      if (product is ProductModel) {
        return SimilarProducts.getColorForProduct(product);
      } else {
        // Create a ProductModel from the Product
        // Only use the properties that are available in the ProductModel constructor
        final productModel = ProductModel(
          id: product.id,
          name: product.name,
          price: product.price,
          image: product.image,
          categoryId: product.categoryId,
          description: product.description,
          mrp: product.mrp,
          inStock: product.inStock,
          subcategoryId: product.subcategoryId,
          tags: product.tags,
          isFeatured: product.isFeatured,
          isActive: product.isActive,
        );
        return SimilarProducts.getColorForProduct(productModel);
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_CART', 'Error getting background color for product: ${product.id}', e);
      return null;
    }
  }
}