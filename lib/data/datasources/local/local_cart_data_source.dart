import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/cart.dart';
import '../../../utils/cart_logger.dart';

/// Local cache for cart data to provide faster loading and offline functionality
class LocalCartDataSource {
  final SharedPreferences sharedPreferences;
  static const String CART_CACHE_KEY = 'cached_cart';
  
  LocalCartDataSource({required this.sharedPreferences});
  
  /// Save cart to local storage
  Future<bool> saveCart(Cart cart) async {
    try {
      CartLogger.log('LOCAL_CART', 'Saving cart to local storage');
      
      // Convert to JSON
      final jsonString = jsonEncode({
        'items': cart.items.map((item) => {
          'productId': item.productId,
          'name': item.name,
          'image': item.image,
          'price': item.price,
          'mrp': item.mrp,
          'quantity': item.quantity,
          'categoryId': item.categoryId,
          'categoryName': item.categoryName,
        }).toList(),
        'subtotal': cart.subtotal,
        'discount': cart.discount,
        'deliveryFee': cart.deliveryFee,
        'total': cart.total,
        'itemCount': cart.itemCount,
        'appliedCouponCode': cart.appliedCouponCode,
      });
      
      // Save to SharedPreferences
      final result = await sharedPreferences.setString(CART_CACHE_KEY, jsonString);
      
      if (result) {
        CartLogger.success('LOCAL_CART', 'Cart saved to local storage');
      } else {
        CartLogger.error('LOCAL_CART', 'Failed to save cart to local storage');
      }
      
      return result;
    } catch (e) {
      CartLogger.error('LOCAL_CART', 'Error saving cart to local storage: $e');
      return false;
    }
  }
  
  /// Get cart from local storage
  Future<Cart?> getCart() async {
    try {
      CartLogger.log('LOCAL_CART', 'Getting cart from local storage');
      
      // Get from SharedPreferences
      final jsonString = sharedPreferences.getString(CART_CACHE_KEY);
      
      if (jsonString == null) {
        CartLogger.info('LOCAL_CART', 'No cart found in local storage');
        return null;
      }
      
      // Parse JSON
      final jsonMap = jsonDecode(jsonString);
      
      // Parse items
      final itemsList = (jsonMap['items'] as List<dynamic>);
      final items = itemsList.map((item) => CartItem(
        productId: item['productId'],
        name: item['name'],
        image: item['image'],
        price: (item['price'] as num).toDouble(),
        mrp: item['mrp'] != null ? (item['mrp'] as num).toDouble() : null,
        quantity: item['quantity'],
        categoryId: item['categoryId'],
        categoryName: item['categoryName'],
      )).toList();
      
      // Create cart object - we need a userId, get from SharedPreferences
      final userId = sharedPreferences.getString('user_token') ?? 'unknown';
      final cart = Cart(
        userId: userId,
        items: items,
        discount: (jsonMap['discount'] as num).toDouble(),
        deliveryFee: (jsonMap['deliveryFee'] as num).toDouble(),
        appliedCouponCode: jsonMap['appliedCouponCode'],
      );
      
      CartLogger.success('LOCAL_CART', 'Retrieved cart from local storage with ${items.length} items');
      return cart;
    } catch (e) {
      CartLogger.error('LOCAL_CART', 'Error getting cart from local storage: $e');
      return null;
    }
  }
  
  /// Clear cart from local storage
  Future<bool> clearCart() async {
    try {
      CartLogger.log('LOCAL_CART', 'Clearing cart from local storage');
      
      // Remove from SharedPreferences
      final result = await sharedPreferences.remove(CART_CACHE_KEY);
      
      if (result) {
        CartLogger.success('LOCAL_CART', 'Cart cleared from local storage');
      } else {
        CartLogger.error('LOCAL_CART', 'Failed to clear cart from local storage');
      }
      
      return result;
    } catch (e) {
      CartLogger.error('LOCAL_CART', 'Error clearing cart from local storage: $e');
      return false;
    }
  }
}
