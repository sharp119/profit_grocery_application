import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';
import '../../../utils/cart_logger.dart';
import '../../models/cart_model.dart';

abstract class CartLocalDataSource {
  /// Gets the cached [CartModel] which was gotten the last time
  /// the user had an internet connection.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<CartModel> getLastCart(String userId);

  /// Cache the [CartModel] to local storage.
  Future<bool> cacheCart(CartModel cartToCache);

  /// Clear the cached [CartModel].
  Future<bool> clearCart(String userId);
}

const CACHED_CART_PREFIX = 'CACHED_CART_';

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences sharedPreferences;

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<CartModel> getLastCart(String userId) async {
    CartLogger.log('LOCAL', 'Getting cached cart for user: $userId');
    final jsonString = sharedPreferences.getString('$CACHED_CART_PREFIX$userId');
    if (jsonString != null) {
      try {
        CartLogger.info('LOCAL', 'Found cached cart data, parsing JSON');
        final cartModel = CartModel.fromJson(json.decode(jsonString));
        CartLogger.success('LOCAL', 'Successfully parsed cached cart, items: ${cartModel.items.length}, total: ${cartModel.total}');
        return cartModel;
      } catch (e) {
        CartLogger.error('LOCAL', 'Error parsing cached cart JSON', e);
        // If there's an error parsing the JSON, return an empty cart
        return CartModel.empty(userId);
      }
    } else {
      CartLogger.info('LOCAL', 'No cached cart found, returning empty cart');
      return CartModel.empty(userId);
    }
  }

  @override
  Future<bool> cacheCart(CartModel cartToCache) async {
    final userId = cartToCache.userId;
    CartLogger.log('LOCAL', 'Caching cart for user: $userId with ${cartToCache.items.length} items');
    
    try {
      // Convert cart to JSON
      final jsonString = json.encode(cartToCache.toJson());
      CartLogger.info('LOCAL', 'Cart JSON to cache: $jsonString');
      
      // Save to SharedPreferences
      final result = await sharedPreferences.setString(
        '$CACHED_CART_PREFIX$userId',
        jsonString,
      );
      
      if (result) {
        CartLogger.success('LOCAL', 'Successfully cached cart');
      } else {
        CartLogger.error('LOCAL', 'Failed to cache cart');
      }
      
      return result;
    } catch (e) {
      CartLogger.error('LOCAL', 'Error caching cart', e);
      return false;
    }
  }

  @override
  Future<bool> clearCart(String userId) async {
    CartLogger.log('LOCAL', 'Clearing cached cart for user: $userId');
    try {
      final result = await sharedPreferences.remove('$CACHED_CART_PREFIX$userId');
      
      if (result) {
        CartLogger.success('LOCAL', 'Successfully cleared cached cart');
      } else {
        CartLogger.error('LOCAL', 'Failed to clear cached cart');
      }
      
      return result;
    } catch (e) {
      CartLogger.error('LOCAL', 'Error clearing cached cart', e);
      return false;
    }
  }
}
