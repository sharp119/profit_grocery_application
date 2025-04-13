import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../utils/cart_logger.dart';
import '../../../models/cart_model.dart';

abstract class CartRemoteDataSource {
  /// Gets the [CartModel] for the provided user ID from Firebase Realtime Database.
  Future<CartModel> getCart(String userId);

  /// Updates the [CartModel] in Firebase Realtime Database.
  Future<CartModel> updateCart(CartModel cart);

  /// Adds an item to the user's cart.
  Future<CartModel> addCartItem(String userId, CartItemModel item);

  /// Updates the quantity of an item in the user's cart.
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity);

  /// Removes an item from the user's cart.
  Future<CartModel> removeCartItem(String userId, String productId);

  /// Clears all items from the user's cart.
  Future<CartModel> clearCart(String userId);

  /// Applies a coupon to the user's cart.
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount);

  /// Removes the applied coupon from the user's cart.
  Future<CartModel> removeCoupon(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseDatabase database;
  // Keep track of which references have already been set to keepSynced
  final Set<String> _syncedReferences = {};
  bool _persistenceEnabled = false;

  CartRemoteDataSourceImpl({required this.database}) {
    // Initialize database settings only once during construction
    _initializeDatabase();
  }
  
  // One-time initialization method
  Future<void> _initializeDatabase() async {
    try {
      CartLogger.log('REMOTE', 'Initializing Firebase Realtime Database...');
      
      // Enable persistence for offline support - only once
      if (!_persistenceEnabled) {
        try {
          // Call without await since method returns void
          database.setPersistenceEnabled(true);
          _persistenceEnabled = true;
          CartLogger.log('REMOTE', 'Firebase persistence enabled successfully');
        } catch (e) {
          // Persistence might already be enabled, ignore this error
          CartLogger.info('REMOTE', 'Note: Firebase persistence already configured');
          _persistenceEnabled = true;
        }
      }
      
      // Test connection
      await _testConnection();
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to initialize database', e);
    }
  }
  
  // Helper method to safely enable syncing for a path only once
  Future<void> _ensureSynced(String path) async {
    if (!_syncedReferences.contains(path)) {
      try {
        final ref = database.ref().child(path);
        await ref.keepSynced(true);
        _syncedReferences.add(path);
        CartLogger.info('REMOTE', 'Enabled sync for path: $path');
      } catch (e) {
        CartLogger.error('REMOTE', 'Failed to enable sync for path: $path', e);
      }
    }
  }
  
  // Simple test to verify database connection
  Future<void> _testConnection() async {
    try {
      CartLogger.log('REMOTE', 'Testing Firebase Realtime Database connection...');
      
      // Write to a simple test path
      final testRef = database.ref().child('test_connection');
      await testRef.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });
      
      CartLogger.success('REMOTE', 'Successfully connected to Firebase Realtime Database');
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to connect to Firebase Realtime Database', e);
    }
  }

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      CartLogger.log('REMOTE', 'Fetching cart from Firebase for user: $userId');
      
      // Build the path
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      
      // Make sure sync is enabled - but don't call repeatedly
      await _ensureSynced(cartPath);
      
      // Get the reference without calling keepSynced again
      final ref = database.ref().child(cartPath);
      
      try {
        // Attempt to fetch data
        final snapshot = await ref.get();
        
        CartLogger.info('REMOTE', 'Firebase cart snapshot exists: ${snapshot.exists}, hasValue: ${snapshot.value != null}');
        
        if (snapshot.exists && snapshot.value != null) {
          try {
            // Parse data from Firebase
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            CartLogger.log('REMOTE', 'Successfully parsed cart data from Firebase');
            return CartModel.fromJson(data);
          } catch (parsingError) {
            CartLogger.error('REMOTE', 'Error parsing cart data from Firebase', parsingError);
            return CartModel.empty(userId);
          }
        } else {
          CartLogger.log('REMOTE', 'No cart data found in Firebase, returning empty cart');
          return CartModel.empty(userId);
        }
      } catch (fetchError) {
        CartLogger.error('REMOTE', 'Error fetching cart data', fetchError);
        return CartModel.empty(userId);
      }
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to fetch cart data from Firebase', e);
      return CartModel.empty(userId);
    }
  }

  @override
  Future<CartModel> updateCart(CartModel cart) async {
    try {
      final userId = cart.userId;
      CartLogger.log('REMOTE', 'Updating cart in Firebase for user: $userId');
      
      // Use the consistent path structure
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      
      // Convert cart to JSON
      final cartJson = cart.toJson();
      CartLogger.info('REMOTE', 'Cart JSON to update: $cartJson');
      
      // Write to Firebase with retry
      bool success = false;
      Exception? lastError;
      
      for (int i = 0; i < 3; i++) {
        try {
          await ref.set(cartJson);
          CartLogger.success('REMOTE', 'Successfully updated cart in Firebase');
          success = true;
          break;
        } catch (e) {
          lastError = ServerException(message: 'Failed to update cart: $e');
          
          if (i < 2) {
            // Wait before retrying
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      if (!success && lastError != null) {
        throw lastError;
      }
      
      return cart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to update cart in Firebase', e);
      throw ServerException(message: 'Failed to update cart: $e');
    }
  }

  @override
  Future<CartModel> addCartItem(String userId, CartItemModel item) async {
    try {
      CartLogger.log('REMOTE', 'Adding item to cart in Firebase: ${item.name} (${item.productId}), quantity: ${item.quantity}');
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Check if item already exists
      final existingItemIndex = currentCart.items.indexWhere(
        (cartItem) => cartItem.productId == item.productId
      );
      
      // Create updated cart items list
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      );
      
      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = updatedItems[existingItemIndex];
        final newQuantity = existingItem.quantity + item.quantity;
        CartLogger.info('REMOTE', 'Item already exists in cart. Updating quantity from ${existingItem.quantity} to $newQuantity');
        
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity
        ) as CartItemModel;
      } else {
        // Add new item
        CartLogger.info('REMOTE', 'Adding new item to cart');
        updatedItems.add(item);
      }
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Use direct path for better reliability
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(updatedCart.toJson());
      CartLogger.success('REMOTE', 'Successfully added item to cart in Firebase');
      
      return updatedCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to add item to cart in Firebase', e);
      throw ServerException(message: 'Failed to add item to cart: $e');
    }
  }

  @override
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity) async {
    try {
      CartLogger.log('REMOTE', 'Updating cart item quantity in Firebase for user: $userId, product: $productId, quantity: $quantity');
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Find item index
      final itemIndex = currentCart.items.indexWhere(
        (item) => item.productId == productId
      );
      
      if (itemIndex == -1) {
        throw ServerException(message: 'Item not found in cart');
      }
      
      // Create updated cart items list
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      );
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        updatedItems.removeAt(itemIndex);
      } else {
        // Update item quantity
        final item = updatedItems[itemIndex];
        updatedItems[itemIndex] = item.copyWith(quantity: quantity) as CartItemModel;
      }
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Save to Firebase directly
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(updatedCart.toJson());
      
      return updatedCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to update item quantity', e);
      throw ServerException(message: 'Failed to update item quantity: $e');
    }
  }

  @override
  Future<CartModel> removeCartItem(String userId, String productId) async {
    try {
      CartLogger.log('REMOTE', 'Removing item from cart in Firebase for user: $userId, product: $productId');
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Create updated cart items list with the item removed
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      )..removeWhere((item) => item.productId == productId);
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Save to Firebase directly
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(updatedCart.toJson());
      
      return updatedCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to remove item from cart', e);
      throw ServerException(message: 'Failed to remove item from cart: $e');
    }
  }

  @override
  Future<CartModel> clearCart(String userId) async {
    try {
      CartLogger.log('REMOTE', 'Clearing cart in Firebase for user: $userId');
      
      // Create empty cart
      final emptyCart = CartModel.empty(userId);
      
      // Save to Firebase directly
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(emptyCart.toJson());
      
      return emptyCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to clear cart', e);
      throw ServerException(message: 'Failed to clear cart: $e');
    }
  }

  @override
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount) async {
    try {
      CartLogger.log('REMOTE', 'Applying coupon in Firebase for user: $userId, coupon: $couponCode');
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Apply coupon
      final updatedCart = currentCart.copyWith(
        appliedCouponId: couponId,
        appliedCouponCode: couponCode,
        discount: discount
      ) as CartModel;
      
      // Save to Firebase directly
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(updatedCart.toJson());
      
      return updatedCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to apply coupon', e);
      throw ServerException(message: 'Failed to apply coupon: $e');
    }
  }

  @override
  Future<CartModel> removeCoupon(String userId) async {
    try {
      CartLogger.log('REMOTE', 'Removing coupon from cart in Firebase for user: $userId');
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Remove coupon
      final updatedCart = currentCart.copyWith(
        appliedCouponId: null,
        appliedCouponCode: null,
        discount: 0.0
      ) as CartModel;
      
      // Save to Firebase directly
      final cartPath = '${AppConstants.cartsCollection}/$userId';
      final ref = database.ref().child(cartPath);
      await ref.set(updatedCart.toJson());
      
      return updatedCart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to remove coupon', e);
      throw ServerException(message: 'Failed to remove coupon: $e');
    }
  }
}