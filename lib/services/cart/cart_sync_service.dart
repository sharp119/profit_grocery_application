import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import '../../data/models/cart_model.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../utils/cart_logger.dart';

/// Service to handle synchronization between local and remote cart data
class CartSyncService {
  final CartRepository cartRepository;
  final SharedPreferences sharedPreferences;
  final FirebaseDatabase database;
  final Connectivity connectivity;
  
  // Keys for pending operations
  static const String _pendingOperationsKey = 'PENDING_CART_OPERATIONS';
  
  // Stream controller for sync events
  final _syncStreamController = StreamController<CartSyncStatus>.broadcast();
  Stream<CartSyncStatus> get syncStream => _syncStreamController.stream;
  
  // Stream subscription for connectivity changes
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  CartSyncService({
    required this.cartRepository,
    required this.sharedPreferences,
    required this.database,
    required this.connectivity,
  });
  
  // Initialize the sync service
  Future<void> init() async {
    CartLogger.log('SYNC', 'Initializing CartSyncService');
    // Listen for connectivity changes
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((result) {
      CartLogger.info('SYNC', 'Connectivity changed: $result');
      if (result != ConnectivityResult.none) {
        // We're back online, try to sync pending operations
        CartLogger.log('SYNC', 'Back online, processing pending operations');
        _processPendingOperations();
      }
    });
    
    // Check if we have pending operations and try to process them
    await _processPendingOperations();
    CartLogger.success('SYNC', 'CartSyncService initialized');
  }
  
  // Dispose the sync service
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStreamController.close();
  }
  
  // Add an operation to the pending list
  Future<void> _addPendingOperation(CartOperation operation) async {
    CartLogger.log('SYNC', 'Adding operation to pending list: ${operation.type}');
    final List<String> pendingOperations = sharedPreferences.getStringList(_pendingOperationsKey) ?? [];
    pendingOperations.add(operation.toJson());
    await sharedPreferences.setStringList(_pendingOperationsKey, pendingOperations);
    CartLogger.info('SYNC', 'Pending operations count: ${pendingOperations.length}');
  }
  
  // Process pending operations
  Future<void> _processPendingOperations() async {
    try {
      final List<String> pendingOperations = sharedPreferences.getStringList(_pendingOperationsKey) ?? [];
      
      if (pendingOperations.isEmpty) {
        CartLogger.info('SYNC', 'No pending operations to process');
        return;
      }
      
      CartLogger.log('SYNC', 'Processing ${pendingOperations.length} pending operations');
      _syncStreamController.add(CartSyncStatus.syncing);
      
      // Check if we have internet connection
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CartLogger.info('SYNC', 'Device is offline, cannot process pending operations');
        _syncStreamController.add(CartSyncStatus.offline);
        return;
      }
      
      int successCount = 0;
      int failCount = 0;
      
      // Process each operation in order
      for (int i = 0; i < pendingOperations.length; i++) {
        CartLogger.info('SYNC', 'Processing operation ${i+1}/${pendingOperations.length}');
        final operation = CartOperation.fromJson(pendingOperations[i]);
        
        // Process the operation based on type
        final result = await _processOperation(operation);
        
        // Handle the result
        result.fold(
          (failure) {
            // Failed to process operation
            CartLogger.error('SYNC', 'Failed to process operation: ${failure.message}');
            failCount++;
            
            if (failure is NetworkFailure) {
              // If network failure, stop processing
              CartLogger.error('SYNC', 'Network failure, stopping sync');
              _syncStreamController.add(CartSyncStatus.offline);
              return;
            }
            // For other failures, continue with next operation
          },
          (success) {
            // Operation successful, remove it from the list
            CartLogger.success('SYNC', 'Successfully processed operation');
            pendingOperations.removeAt(i);
            i--; // Adjust index
            successCount++;
          }
        );
      }
      
      CartLogger.log('SYNC', 'Processed operations - Success: $successCount, Failed: $failCount');
      
      // Save updated pending operations list
      await sharedPreferences.setStringList(_pendingOperationsKey, pendingOperations);
      
      // All operations processed successfully
      if (pendingOperations.isEmpty) {
        CartLogger.success('SYNC', 'All pending operations processed successfully');
        _syncStreamController.add(CartSyncStatus.synced);
      } else {
        CartLogger.info('SYNC', '${pendingOperations.length} operations still pending');
        _syncStreamController.add(CartSyncStatus.partialSync);
      }
    } catch (e, stackTrace) {
      CartLogger.error('SYNC', 'Error processing pending operations', e, stackTrace);
      _syncStreamController.add(CartSyncStatus.error);
    }
  }
  
  // Process a single operation
  Future<Either<Failure, bool>> _processOperation(CartOperation operation) async {
    try {
      CartLogger.log('SYNC', 'Processing operation: ${operation.type}');
      
      switch(operation.type) {
        case CartOperationType.add:
          // Check if required fields are not null
          if (operation.productId == null || operation.name == null || 
              operation.image == null || operation.price == null || 
              operation.quantity == null) {
            CartLogger.error('SYNC', 'Missing required fields for add operation');
            return Left(ServerFailure(message: 'Missing required fields for add operation'));
          }
          
          CartLogger.info('SYNC', 'Adding item to cart: ${operation.name} (${operation.productId})');
          
          // Add item to cart
          await cartRepository.addToCart(
            userId: operation.userId,
            productId: operation.productId!,
            name: operation.name!,
            image: operation.image!,
            price: operation.price!,
            quantity: operation.quantity!,
            categoryId: operation.categoryId,
            categoryName: operation.categoryName,
          );
          CartLogger.success('SYNC', 'Successfully added item to cart');
          return const Right(true);
          
        case CartOperationType.update:
          // Check if required fields are not null
          if (operation.productId == null || operation.quantity == null) {
            return Left(ServerFailure(message: 'Missing required fields for update operation'));
          }
          
          // Update item quantity
          await cartRepository.updateCartItemQuantity(
            userId: operation.userId,
            productId: operation.productId!,
            quantity: operation.quantity!,
          );
          return const Right(true);
          
        case CartOperationType.remove:
          // Check if required fields are not null
          if (operation.productId == null) {
            return Left(ServerFailure(message: 'Missing productId for remove operation'));
          }
          
          // Remove item from cart
          await cartRepository.removeFromCart(
            userId: operation.userId,
            productId: operation.productId!,
          );
          return const Right(true);
          
        case CartOperationType.clear:
          // Clear cart
          await cartRepository.clearCart(operation.userId);
          return const Right(true);
          
        case CartOperationType.applyCoupon:
          // Check if required fields are not null
          if (operation.couponCode == null) {
            return Left(ServerFailure(message: 'Missing couponCode for apply coupon operation'));
          }
          
          // Apply coupon
          await cartRepository.applyCoupon(
            userId: operation.userId,
            couponCode: operation.couponCode!,
          );
          return const Right(true);
          
        case CartOperationType.removeCoupon:
          // Remove coupon
          await cartRepository.removeCoupon(operation.userId);
          return const Right(true);
          
        default:
          return Left(ServerFailure(message: 'Unknown operation type'));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  // Enqueue an operation to add an item to cart
  Future<Either<Failure, Cart>> addToCart({
    required String userId,
    required String productId,
    required String name,
    required String image,
    required double price,
    required int quantity,
    String? categoryId,
    String? categoryName, double? mrp,
  }) async {
    // Try to perform the operation directly
    final result = await cartRepository.addToCart(
      userId: userId,
      productId: productId,
      name: name,
      image: image,
      price: price,
      quantity: quantity,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.add,
            userId: userId,
            productId: productId,
            name: name,
            image: image,
            price: price,
            quantity: quantity,
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        );
        
        // Return local cart
        final localCart = result.fold(
          (failure) => CartModel.empty(userId),
          (cart) => cart,
        );
        
        return Right(localCart);
      }
    }
    
    return result;
  }
  
  // Enqueue an operation to update an item quantity
  Future<Either<Failure, Cart>> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    // Try to perform the operation directly
    final result = await cartRepository.updateCartItemQuantity(
      userId: userId,
      productId: productId,
      quantity: quantity,
    );
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.update,
            userId: userId,
            productId: productId,
            quantity: quantity,
          ),
        );
        
        // Return local cart
        final localCart = result.fold(
          (failure) => CartModel.empty(userId),
          (cart) => cart,
        );
        
        return Right(localCart);
      }
    }
    
    return result;
  }
  
  // Enqueue an operation to remove an item from cart
  Future<Either<Failure, Cart>> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    // Try to perform the operation directly
    final result = await cartRepository.removeFromCart(
      userId: userId,
      productId: productId,
    );
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.remove,
            userId: userId,
            productId: productId,
          ),
        );
        
        // Return local cart
        final localCart = result.fold(
          (failure) => CartModel.empty(userId),
          (cart) => cart,
        );
        
        return Right(localCart);
      }
    }
    
    return result;
  }
  
  // Enqueue an operation to clear the cart
  Future<Either<Failure, Cart>> clearCart(String userId) async {
    // Try to perform the operation directly
    final result = await cartRepository.clearCart(userId);
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.clear,
            userId: userId,
          ),
        );
        
        // Return empty cart
        return Right(CartModel.empty(userId));
      }
    }
    
    return result;
  }
  
  // Enqueue an operation to apply a coupon
  Future<Either<Failure, Cart>> applyCoupon({
    required String userId,
    required String couponCode,
  }) async {
    // Try to perform the operation directly
    final result = await cartRepository.applyCoupon(
      userId: userId,
      couponCode: couponCode,
    );
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.applyCoupon,
            userId: userId,
            couponCode: couponCode,
          ),
        );
        
        // Return local cart
        final localCart = result.fold(
          (failure) => CartModel.empty(userId),
          (cart) => cart,
        );
        
        return Right(localCart);
      }
    }
    
    return result;
  }
  
  // Enqueue an operation to remove a coupon
  Future<Either<Failure, Cart>> removeCoupon(String userId) async {
    // Try to perform the operation directly
    final result = await cartRepository.removeCoupon(userId);
    
    // If failed due to network, add to pending operations
    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (cart) => null,
      );
      
      if (failure is NetworkFailure) {
        await _addPendingOperation(
          CartOperation(
            type: CartOperationType.removeCoupon,
            userId: userId,
          ),
        );
        
        // Return local cart
        final localCart = result.fold(
          (failure) => CartModel.empty(userId),
          (cart) => cart,
        );
        
        return Right(localCart);
      }
    }
    
    return result;
  }
  
  // Force sync all pending operations
  Future<CartSyncStatus> forceSync() async {
    await _processPendingOperations();
    
    // Check if we have any pending operations left
    final pendingOperations = sharedPreferences.getStringList(_pendingOperationsKey) ?? [];
    
    if (pendingOperations.isEmpty) {
      return CartSyncStatus.synced;
    } else {
      return CartSyncStatus.partialSync;
    }
  }
  
  // Get current sync status
  Future<CartSyncStatus> getCurrentSyncStatus() async {
    final pendingOperations = sharedPreferences.getStringList(_pendingOperationsKey) ?? [];
    
    if (pendingOperations.isEmpty) {
      return CartSyncStatus.synced;
    }
    
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return CartSyncStatus.offline;
    }
    
    return CartSyncStatus.pendingSync;
  }
}

// Operation types
enum CartOperationType {
  add,
  update,
  remove,
  clear,
  applyCoupon,
  removeCoupon,
}

// Sync status
enum CartSyncStatus {
  synced,       // All operations synchronized
  syncing,      // Currently synchronizing
  pendingSync,  // Has pending operations to sync
  partialSync,  // Some operations synced, some failed
  offline,      // Offline, can't sync
  error,        // Error occurred during sync
}

// Cart operation model
class CartOperation {
  final CartOperationType type;
  final String userId;
  final String? productId;
  final String? name;
  final String? image;
  final double? price;
  final int? quantity;
  final String? categoryId;
  final String? categoryName;
  final String? couponCode;
  
  CartOperation({
    required this.type,
    required this.userId,
    this.productId,
    this.name,
    this.image,
    this.price,
    this.quantity,
    this.categoryId,
    this.categoryName,
    this.couponCode,
  });
  
  // Convert to JSON string
  String toJson() {
    return """
    {
      "type": "${type.toString().split('.').last}",
      "userId": "$userId",
      "productId": ${productId != null ? '"$productId"' : 'null'},
      "name": ${name != null ? '"$name"' : 'null'},
      "image": ${image != null ? '"$image"' : 'null'},
      "price": $price,
      "quantity": $quantity,
      "categoryId": ${categoryId != null ? '"$categoryId"' : 'null'},
      "categoryName": ${categoryName != null ? '"$categoryName"' : 'null'},
      "couponCode": ${couponCode != null ? '"$couponCode"' : 'null'}
    }
    """;
  }
  
  // Create from JSON string
  factory CartOperation.fromJson(String json) {
    // Simple parsing as we know the exact format
    final typeString = _extractValue(json, "type");
    final userId = _extractValue(json, "userId");
    final productId = _extractValue(json, "productId");
    final name = _extractValue(json, "name");
    final image = _extractValue(json, "image");
    final priceString = _extractValue(json, "price");
    final quantityString = _extractValue(json, "quantity");
    final categoryId = _extractValue(json, "categoryId");
    final categoryName = _extractValue(json, "categoryName");
    final couponCode = _extractValue(json, "couponCode");
    
    // Parse type
    CartOperationType type;
    switch (typeString) {
      case "add":
        type = CartOperationType.add;
        break;
      case "update":
        type = CartOperationType.update;
        break;
      case "remove":
        type = CartOperationType.remove;
        break;
      case "clear":
        type = CartOperationType.clear;
        break;
      case "applyCoupon":
        type = CartOperationType.applyCoupon;
        break;
      case "removeCoupon":
        type = CartOperationType.removeCoupon;
        break;
      default:
        throw Exception("Unknown operation type: $typeString");
    }
    
    return CartOperation(
      type: type,
      userId: userId,
      productId: productId == "null" ? null : productId,
      name: name == "null" ? null : name,
      image: image == "null" ? null : image,
      price: priceString == "null" ? null : double.parse(priceString),
      quantity: quantityString == "null" ? null : int.parse(quantityString),
      categoryId: categoryId == "null" ? null : categoryId,
      categoryName: categoryName == "null" ? null : categoryName,
      couponCode: couponCode == "null" ? null : couponCode,
    );
  }
  
  // Helper method to extract values from JSON string
  static String _extractValue(String json, String key) {
    final regex = RegExp('"$key":\\s*(?:"([^"]*)"|(null|\\d+\\.?\\d*))');
    final match = regex.firstMatch(json);
    if (match != null) {
      return match.group(1) ?? match.group(2) ?? "null";
    }
    return "null";
  }
}