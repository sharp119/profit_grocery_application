import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';
import '../../models/cart_model.dart';

abstract class CartLocalDataSource {
  /// Gets the cached [CartModel] which was gotten the last time
  /// the user had an internet connection.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<CartModel> getLastCart(String userId);

  /// Cache the [CartModel] to local storage.
  Future<void> cacheCart(CartModel cartToCache);

  /// Clear the cached [CartModel].
  Future<void> clearCart(String userId);
}

const CACHED_CART_PREFIX = 'CACHED_CART_';

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences sharedPreferences;

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<CartModel> getLastCart(String userId) async {
    final jsonString = sharedPreferences.getString('$CACHED_CART_PREFIX$userId');
    if (jsonString != null) {
      return CartModel.fromJson(json.decode(jsonString));
    } else {
      return CartModel.empty(userId);
    }
  }

  @override
  Future<Future<bool>> cacheCart(CartModel cartToCache) async {
    final userId = cartToCache.userId;
    return sharedPreferences.setString(
      '$CACHED_CART_PREFIX$userId',
      json.encode(cartToCache.toJson()),
    );
  }

  @override
  Future<Future<bool>> clearCart(String userId) async {
    return sharedPreferences.remove('$CACHED_CART_PREFIX$userId');
  }
}
