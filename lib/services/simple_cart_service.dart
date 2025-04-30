import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../core/constants/app_constants.dart';

/// A simple service to handle cart operations with minimal data - only product IDs and quantities
class SimpleCartService {
  static final SimpleCartService _instance = SimpleCartService._internal();
  
  factory SimpleCartService() {
    return _instance;
  }
  
  SimpleCartService._internal();
  
  // Keys for SharedPreferences
  static const String _cartItemsKey = 'simple_cart_items';
  
  /// Add or update an item in the cart
  Future<void> addOrUpdateItem({required String productId, required int quantity}) async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null) {
        print('SimpleCartService: User ID not found, cannot add item to cart');
        return;
      }
      
      // If quantity is 0 or less, remove item
      if (quantity <= 0) {
        await removeItem(productId: productId);
        return;
      }
      
      // Save in cache
      await _saveToCache(productId, quantity);
      
      // Save in Firestore
      await _saveToFirestore(userId, productId, quantity);
      
      print('SimpleCartService: Successfully added/updated item in cart: $productId, quantity: $quantity');
    } catch (e) {
      print('SimpleCartService: Error adding/updating item in cart: $e');
    }
  }
  
  /// Remove an item from the cart
  Future<void> removeItem({required String productId}) async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null) {
        print('SimpleCartService: User ID not found, cannot remove item from cart');
        return;
      }
      
      // Remove from cache
      await _removeFromCache(productId);
      
      // Remove from Firestore
      await _removeFromFirestore(userId, productId);
      
      print('SimpleCartService: Successfully removed item from cart: $productId');
    } catch (e) {
      print('SimpleCartService: Error removing item from cart: $e');
    }
  }
  
  /// Save cart item to SharedPreferences cache
  Future<void> _saveToCache(String productId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing cart items from cache
      final cartItemsJson = prefs.getString(_cartItemsKey);
      Map<String, dynamic> cartItems = {};
      
      if (cartItemsJson != null) {
        // Parse existing items
        cartItems = jsonDecode(cartItemsJson);
      }
      
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if item already exists
      if (cartItems.containsKey(productId)) {
        // Update existing item
        final itemData = cartItems[productId] as Map<String, dynamic>;
        itemData['quantity'] = quantity;
        itemData['lastModified'] = currentTime;
      } else {
        // Add new item
        cartItems[productId] = {
          'quantity': quantity,
          'addedAt': currentTime,
          'lastModified': currentTime,
        };
      }
      
      // Save updated cart items to cache
      await prefs.setString(_cartItemsKey, jsonEncode(cartItems));
      
      print('SimpleCartService: Saved to cache - $productId: $quantity');
    } catch (e) {
      print('SimpleCartService: Error saving to cache: $e');
    }
  }
  
  /// Remove cart item from SharedPreferences cache
  Future<void> _removeFromCache(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing cart items from cache
      final cartItemsJson = prefs.getString(_cartItemsKey);
      
      if (cartItemsJson == null) {
        return; // No items to remove
      }
      
      // Parse existing items
      final Map<String, dynamic> cartItems = jsonDecode(cartItemsJson);
      
      // Remove item
      cartItems.remove(productId);
      
      // Save updated cart items to cache
      await prefs.setString(_cartItemsKey, jsonEncode(cartItems));
      
      print('SimpleCartService: Removed from cache - $productId');
    } catch (e) {
      print('SimpleCartService: Error removing from cache: $e');
    }
  }
  
  /// Save cart item to Firestore
  Future<void> _saveToFirestore(String userId, String productId, int quantity) async {
    try {
      final database = FirebaseDatabase.instance;
      final cartItemsRef = database.ref().child('${AppConstants.cartsCollection}/$userId/items');
      
      // Check if the item already exists
      final snapshot = await cartItemsRef.child(productId).get();
      final currentTime = ServerValue.timestamp;
      
      if (snapshot.exists) {
        // Update existing item
        await cartItemsRef.child(productId).update({
          'productId': productId,
          'quantity': quantity,
          'lastModified': currentTime,
        });
      } else {
        // Add new item
        await cartItemsRef.child(productId).set({
          'productId': productId,
          'quantity': quantity,
          'addedAt': currentTime,
          'lastModified': currentTime,
        });
      }
      
      print('SimpleCartService: Saved to Firestore - $productId: $quantity');
    } catch (e) {
      print('SimpleCartService: Error saving to Firestore: $e');
    }
  }
  
  /// Remove cart item from Firestore
  Future<void> _removeFromFirestore(String userId, String productId) async {
    try {
      final database = FirebaseDatabase.instance;
      final cartItemRef = database.ref().child('${AppConstants.cartsCollection}/$userId/items/$productId');
      
      // Remove item
      await cartItemRef.remove();
      
      print('SimpleCartService: Removed from Firestore - $productId');
    } catch (e) {
      print('SimpleCartService: Error removing from Firestore: $e');
    }
  }
  
  /// Get all cart items from cache
  Future<Map<String, dynamic>> getCartItemsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = prefs.getString(_cartItemsKey);
      
      if (cartItemsJson == null) {
        return {};
      }
      
      return jsonDecode(cartItemsJson);
    } catch (e) {
      print('SimpleCartService: Error getting items from cache: $e');
      return {};
    }
  }
  
  /// Get all cart items from Firestore
  Future<Map<String, dynamic>> getCartItemsFromFirestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null) {
        print('SimpleCartService: User ID not found, cannot get items from Firestore');
        return {};
      }
      
      final database = FirebaseDatabase.instance;
      final cartItemsRef = database.ref().child('${AppConstants.cartsCollection}/$userId/items');
      
      final snapshot = await cartItemsRef.get();
      
      if (!snapshot.exists) {
        return {};
      }
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, dynamic> cartItems = {};
      
      data.forEach((key, value) {
        final productId = key.toString();
        final item = value as Map<dynamic, dynamic>;
        
        cartItems[productId] = {
          'quantity': item['quantity'],
          'addedAt': item['addedAt'],
          'lastModified': item['lastModified'],
        };
      });
      
      return cartItems;
    } catch (e) {
      print('SimpleCartService: Error getting items from Firestore: $e');
      return {};
    }
  }
  
  /// Sync cache with Firestore (get latest data from Firestore)
  Future<void> syncWithFirestore() async {
    try {
      final firestoreItems = await getCartItemsFromFirestore();
      
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartItemsKey, jsonEncode(firestoreItems));
      
      print('SimpleCartService: Synced cache with Firestore, ${firestoreItems.length} items');
    } catch (e) {
      print('SimpleCartService: Error syncing with Firestore: $e');
    }
  }
} 