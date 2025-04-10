import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../utils/cart_logger.dart';
import '../../../models/cart_model.dart';

abstract class CartRemoteDataSource {
  /// Gets the [CartModel] for the provided user ID from Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> getCart(String userId);

  /// Updates the [CartModel] in Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> updateCart(CartModel cart);

  /// Adds an item to the user's cart.
  ///
  /// If the item already exists, its quantity will be updated.
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> addCartItem(String userId, CartItemModel item);

  /// Updates the quantity of an item in the user's cart.
  ///
  /// If quantity is 0 or less, the item will be removed.
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity);

  /// Removes an item from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> removeCartItem(String userId, String productId);

  /// Clears all items from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> clearCart(String userId);

  /// Applies a coupon to the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount);

  /// Removes the applied coupon from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> removeCoupon(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseDatabase database;
  final uuid = const Uuid();
  String? _sessionId;

  CartRemoteDataSourceImpl({required this.database}) {
    // Debug: Verify database connection on initialization
    _verifyDatabaseConnection();
    _initializeSession();
  }
  
  // Helper method to verify database connection
  Future<void> _verifyDatabaseConnection() async {
    try {
      CartLogger.log('REMOTE', 'Verifying Firebase Realtime Database connection...');
      final testRef = database.ref().child('.info/connected');
      final snapshot = await testRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final connected = snapshot.value as bool;
        CartLogger.log('REMOTE', 'Firebase Realtime Database connection status: ${connected ? "CONNECTED" : "DISCONNECTED"}');
      } else {
        CartLogger.error('REMOTE', 'Unable to determine connection status');
      }
      
      // Test writing to a test path
      try {
        final testWriteRef = database.ref().child('connection_test');
        await testWriteRef.set({
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'test_write'
        });
        CartLogger.success('REMOTE', 'Successfully wrote test data to Firebase Realtime Database');
        
        // Read it back
        final testReadSnapshot = await testWriteRef.get();
        if (testReadSnapshot.exists) {
          CartLogger.success('REMOTE', 'Successfully read test data from Firebase Realtime Database');
        }
      } catch (writeError) {
        CartLogger.error('REMOTE', 'Failed to write test data to Firebase', writeError);
      }
    } catch (e) {
      CartLogger.error('REMOTE', 'Error verifying Firebase connection', e);
    }
  }

  // Initialize session ID
  Future<void> _initializeSession() async {
    try {
      // Get session ID from SharedPreferences or create a new one
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('CART_SESSION_ID');
      
      if (_sessionId == null || _sessionId!.isEmpty) {
        _sessionId = uuid.v4();
        await prefs.setString('CART_SESSION_ID', _sessionId!);
        CartLogger.log('REMOTE', 'Created new cart session ID: $_sessionId');
      } else {
        CartLogger.log('REMOTE', 'Using existing cart session ID: $_sessionId');
      }
    } catch (e) {
      // If there's an error, create a new session ID in memory
      _sessionId = uuid.v4();
      CartLogger.error('REMOTE', 'Error initializing session, using temporary ID: $_sessionId', e);
    }
  }

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      CartLogger.log('REMOTE', 'Fetching cart from Firebase for user: $userId, session: $_sessionId');
      
      // Use the new structure: cartItems --> sessionId --> userId --> cart data
      final ref = database.ref().child('cartItems/$_sessionId/$userId');
      final snapshot = await ref.get();
      
      CartLogger.info('REMOTE', 'Firebase cart snapshot exists: ${snapshot.exists}, hasValue: ${snapshot.value != null}');
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          CartLogger.info('REMOTE', 'Raw Firebase data: ${snapshot.value}');
          final Map<String, dynamic> cartData = {
            'userId': userId,
            'items': <Map<String, dynamic>>[],
            'appliedCouponId': null,
            'appliedCouponCode': null,
            'discount': 0.0,
            'deliveryFee': 0.0,
          };
          
          // Parse cart items
          final Map<dynamic, dynamic> itemsData = snapshot.value as Map;
          final List<CartItemModel> cartItems = [];
          
          for (final entry in itemsData.entries) {
            final String productId = entry.key.toString();
            final Map<dynamic, dynamic> itemData = entry.value as Map;
            
            // Fetch detailed product information based on productId
            final productRef = database.ref().child('products/$productId');
            final productSnapshot = await productRef.get();
            
            String name = 'Product';
            String image = 'assets/images/products/default.png';
            double price = 0.0;
            double? mrp;
            String? categoryId;
            String? categoryName;
            
            // If product details are available, use them
            if (productSnapshot.exists && productSnapshot.value != null) {
              final productData = productSnapshot.value as Map<dynamic, dynamic>;
              name = productData['name']?.toString() ?? 'Product';
              image = productData['image']?.toString() ?? 'assets/images/products/default.png';
              price = double.tryParse(productData['price']?.toString() ?? '0.0') ?? 0.0;
              mrp = double.tryParse(productData['mrp']?.toString() ?? '');
              categoryId = productData['categoryId']?.toString();
              categoryName = productData['categoryName']?.toString();
            }
            
            // Get quantity from cart data
            final int quantity = int.tryParse(itemData['quantity']?.toString() ?? '1') ?? 1;
            
            // Create cart item model
            final cartItem = CartItemModel(
              productId: productId,
              name: name,
              image: image,
              price: price,
              mrp: mrp,
              quantity: quantity,
              categoryId: categoryId,
              categoryName: categoryName,
            );
            
            cartItems.add(cartItem);
          }
          
          // Check for applied coupon
          final couponRef = database.ref().child('cartItems/$_sessionId/$userId/coupon');
          final couponSnapshot = await couponRef.get();
          
          if (couponSnapshot.exists && couponSnapshot.value != null) {
            final couponData = couponSnapshot.value as Map<dynamic, dynamic>;
            cartData['appliedCouponId'] = couponData['id']?.toString();
            cartData['appliedCouponCode'] = couponData['code']?.toString();
            cartData['discount'] = double.tryParse(couponData['discount']?.toString() ?? '0.0') ?? 0.0;
          }
          
          // Create the cart model
          cartData['items'] = cartItems.map((item) => item.toJson()).toList();
          
          CartLogger.log('REMOTE', 'Successfully parsed cart data from Firebase, ${cartItems.length} items');
          return CartModel.fromJson(cartData);
        } catch (parsingError) {
          // Log the error and return empty cart if data cannot be parsed
          CartLogger.error('REMOTE', 'Error parsing cart data from Firebase', parsingError);
          return CartModel.empty(userId);
        }
      } else {
        CartLogger.log('REMOTE', 'No cart data found in Firebase, returning empty cart');
        return CartModel.empty(userId);
      }
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to fetch cart data from Firebase', e);
      throw ServerException(message: 'Failed to fetch cart data: $e');
    }
  }

  @override
  Future<CartModel> updateCart(CartModel cart) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      final userId = cart.userId;
      CartLogger.log('REMOTE', 'Updating cart in Firebase for user: $userId, session: $_sessionId');
      
      // Reference to cart items in the new structure
      final cartRef = database.ref().child('cartItems/$_sessionId/$userId');
      
      // Clear existing cart data
      await cartRef.remove();
      
      // Add each item to the cart
      for (final item in cart.items) {
        final cartItemModel = item as CartItemModel;
        final productId = cartItemModel.productId;
        
        await cartRef.child(productId).set({
          'quantity': cartItemModel.quantity,
          'addedAt': ServerValue.timestamp,
        });
      }
      
      // Add coupon data if applicable
      if (cart.appliedCouponId != null && cart.appliedCouponCode != null) {
        await cartRef.child('coupon').set({
          'id': cart.appliedCouponId,
          'code': cart.appliedCouponCode,
          'discount': cart.discount,
        });
      }
      
      CartLogger.log('REMOTE', 'Firebase update operation completed');
      
      // Return the updated cart (ideally we should fetch it again, but for simplicity we'll return the input cart)
      return cart;
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to update cart in Firebase', e);
      throw ServerException(message: 'Failed to update cart: $e');
    }
  }

  @override
  Future<CartModel> addCartItem(String userId, CartItemModel item) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      CartLogger.log('REMOTE', 'Adding item to cart in Firebase: ${item.name} (${item.productId}), quantity: ${item.quantity}');
      
      // Get current cart
      final currentCart = await getCart(userId);
      CartLogger.info('REMOTE', 'Current cart before adding item has ${currentCart.items.length} items');
      
      // Check if item already exists
      final existingItemIndex = currentCart.items.indexWhere(
        (cartItem) => cartItem.productId == item.productId
      );
      
      // Reference to the specific cart item
      final itemRef = database.ref().child('cartItems/$_sessionId/$userId/${item.productId}');
      
      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = currentCart.items[existingItemIndex] as CartItemModel;
        final newQuantity = existingItem.quantity + item.quantity;
        CartLogger.info('REMOTE', 'Item already exists in cart. Updating quantity from ${existingItem.quantity} to $newQuantity');
        
        await itemRef.update({
          'quantity': newQuantity,
          'updatedAt': ServerValue.timestamp,
        });
        
        // Update the item in the current cart for return
        final List<CartItemModel> updatedItems = List.from(
          currentCart.items.map((item) => item as CartItemModel)
        );
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity
        ) as CartItemModel;
        
        final updatedCart = currentCart.copyWith(
          items: updatedItems
        ) as CartModel;
        
        return updatedCart;
      } else {
        // Add new item
        CartLogger.info('REMOTE', 'Adding new item to cart');
        
        await itemRef.set({
          'quantity': item.quantity,
          'addedAt': ServerValue.timestamp,
        });
        
        // Add the new item to the current cart for return
        final List<CartItemModel> updatedItems = List.from(
          currentCart.items.map((item) => item as CartItemModel)
        );
        updatedItems.add(item);
        
        final updatedCart = currentCart.copyWith(
          items: updatedItems
        ) as CartModel;
        
        CartLogger.info('REMOTE', 'Updated cart has ${updatedCart.items.length} items, total: ${updatedCart.total}');
        
        return updatedCart;
      }
    } catch (e) {
      CartLogger.error('REMOTE', 'Failed to add item to cart in Firebase', e);
      throw ServerException(message: 'Failed to add item to cart: $e');
    }
  }

  @override
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Find item index
      final itemIndex = currentCart.items.indexWhere(
        (item) => item.productId == productId
      );
      
      if (itemIndex == -1) {
        throw ServerException(message: 'Item not found in cart');
      }
      
      // Reference to the specific cart item
      final itemRef = database.ref().child('cartItems/$_sessionId/$userId/$productId');
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        await itemRef.remove();
        
        // Update the cart for return
        final List<CartItemModel> updatedItems = List.from(
          currentCart.items.map((item) => item as CartItemModel)
        );
        updatedItems.removeAt(itemIndex);
        
        final updatedCart = currentCart.copyWith(
          items: updatedItems
        ) as CartModel;
        
        return updatedCart;
      } else {
        // Update item quantity
        await itemRef.update({
          'quantity': quantity,
          'updatedAt': ServerValue.timestamp,
        });
        
        // Update the cart for return
        final List<CartItemModel> updatedItems = List.from(
          currentCart.items.map((item) => item as CartItemModel)
        );
        final item = updatedItems[itemIndex];
        updatedItems[itemIndex] = item.copyWith(quantity: quantity) as CartItemModel;
        
        final updatedCart = currentCart.copyWith(
          items: updatedItems
        ) as CartModel;
        
        return updatedCart;
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update item quantity: $e');
    }
  }

  @override
  Future<CartModel> removeCartItem(String userId, String productId) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Reference to the specific cart item
      final itemRef = database.ref().child('cartItems/$_sessionId/$userId/$productId');
      
      // Remove the item
      await itemRef.remove();
      
      // Update the cart for return
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      )..removeWhere((item) => item.productId == productId);
      
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      return updatedCart;
    } catch (e) {
      throw ServerException(message: 'Failed to remove item from cart: $e');
    }
  }

  @override
  Future<CartModel> clearCart(String userId) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      // Reference to the user's cart
      final cartRef = database.ref().child('cartItems/$_sessionId/$userId');
      
      // Remove all cart items
      await cartRef.remove();
      
      // Return empty cart
      return CartModel.empty(userId);
    } catch (e) {
      throw ServerException(message: 'Failed to clear cart: $e');
    }
  }

  @override
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Reference to the coupon in cart
      final couponRef = database.ref().child('cartItems/$_sessionId/$userId/coupon');
      
      // Add coupon data
      await couponRef.set({
        'id': couponId,
        'code': couponCode,
        'discount': discount,
        'appliedAt': ServerValue.timestamp,
      });
      
      // Return updated cart
      final updatedCart = currentCart.copyWith(
        appliedCouponId: couponId,
        appliedCouponCode: couponCode,
        discount: discount
      ) as CartModel;
      
      return updatedCart;
    } catch (e) {
      throw ServerException(message: 'Failed to apply coupon: $e');
    }
  }

  @override
  Future<CartModel> removeCoupon(String userId) async {
    try {
      if (_sessionId == null) {
        await _initializeSession();
      }
      
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Reference to the coupon in cart
      final couponRef = database.ref().child('cartItems/$_sessionId/$userId/coupon');
      
      // Remove coupon data
      await couponRef.remove();
      
      // Return updated cart
      final updatedCart = currentCart.copyWith(
        appliedCouponId: null,
        appliedCouponCode: null,
        discount: 0.0
      ) as CartModel;
      
      return updatedCart;
    } catch (e) {
      throw ServerException(message: 'Failed to remove coupon: $e');
    }
  }
}
