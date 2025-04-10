import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import 'product_inventory.dart';

/// Defines hardcoded order data for testing and demo purposes
class OrderInventory {
  // Private constructor to prevent instantiation
  OrderInventory._();
  
  // Current order data (for a single active order)
  static Order? _currentOrder;
  
  // Current order status
  // Possible values: order_accepted, getting_packed, out_for_delivery, reached_doorstep, delivered
  static String _currentOrderStatus = 'out_for_delivery';
  
  // Estimated delivery time for current order
  static DateTime _estimatedDeliveryTime = DateTime.now().add(const Duration(minutes: 45));
  
  // Current delivery person details
  static final Map<String, String> _deliveryPersonDetails = {
    'name': 'Raj Kumar',
    'phone': '+91 9876543210',
    'image': 'assets/images/delivery_person.png', // This will fallback to a placeholder
    'rating': '4.8',
  };
  
  // Set current order data
  static void setCurrentOrder(Order order) {
    _currentOrder = order;
  }
  
  // Get current order data
  static Order? getCurrentOrder() {
    return _currentOrder;
  }
  
  // Update current order status
  static void updateCurrentOrderStatus(String status) {
    _currentOrderStatus = status;
  }
  
  // Get current order status
  static String getCurrentOrderStatus() {
    return _currentOrderStatus;
  }
  
  // Get estimated delivery time
  static DateTime getEstimatedDeliveryTime() {
    return _estimatedDeliveryTime;
  }
  
  // Get delivery person details
  static Map<String, String> getDeliveryPersonDetails() {
    return _deliveryPersonDetails;
  }
  
  // Get all dummy orders for a user
  static List<Order> getDummyOrders(String userId) {
    // Always ensure we have at least 3 orders for testing purposes
    return [
      _createDummyOrder(
        id: 'ORD123456',
        userId: userId,
        status: 'delivered',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        products: [
          _createDummyOrderItem('vegetables_fruits_1', 2),
          _createDummyOrderItem('atta_rice_dal_2', 1),
          _createDummyOrderItem('cleaning_household_1', 3),
        ],
      ),
      _createDummyOrder(
        id: 'ORD789012',
        userId: userId,
        status: 'delivered',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        products: [
          _createDummyOrderItem('sweets_chocolates_1', 2),
          _createDummyOrderItem('tea_coffee_milk_3', 1),
          _createDummyOrderItem('chips_namkeen_5', 2),
          _createDummyOrderItem('soft_drinks_1', 1),
        ],
      ),
      _createDummyOrder(
        id: 'ORD345678',
        userId: userId,
        status: 'cancelled',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        products: [
          _createDummyOrderItem('oil_ghee_masala_2', 1),
          _createDummyOrderItem('milk_1', 2),
        ],
      ),
      _createDummyOrder(
        id: 'ORD901234',
        userId: userId,
        status: 'delivered',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        products: [
          _createDummyOrderItem('dry_fruits_cereals_1', 1),
          _createDummyOrderItem('bread_1', 2),
          _createDummyOrderItem('eggs_1', 1),
          _createDummyOrderItem('butter_cheese_2', 1),
        ],
      ),
      _createDummyOrder(
        id: 'ORD567890',
        userId: userId,
        status: 'delivered',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        products: [
          _createDummyOrderItem('hair_care_1', 1),
          _createDummyOrderItem('skin_care_2', 1),
          _createDummyOrderItem('bath_body_1', 2),
          _createDummyOrderItem('personal_care_1', 2),
        ],
      ),
    ];
  }
  
  // Helper method to create a dummy order
  static Order _createDummyOrder({
    required String id,
    required String userId,
    required String status,
    required DateTime createdAt,
    required List<Map<String, dynamic>> products,
  }) {
    // For demo purposes, force the current order to have the 'out_for_delivery' status
    final useStatus = id.contains('${DateTime.now().millisecondsSinceEpoch}') ? 'out_for_delivery' : status;
    // Create order items from product IDs and quantities
    List<OrderItem> orderItems = [];
    double subtotal = 0;
    
    for (final product in products) {
      final productData = ProductInventory.getAllProducts().firstWhere(
        (p) => p.id == product['id'],
        orElse: () => throw Exception('Product not found: ${product['id']}'),
      );
      
      final quantity = product['quantity'] as int;
      final price = productData.price;
      final total = price * quantity;
      
      orderItems.add(OrderItem(
        productId: productData.id,
        productName: productData.name,
        productImage: productData.image,
        price: price,
        quantity: quantity,
        total: total,
      ));
      
      subtotal += total;
    }
    
    // Apply a random discount between 5% and 15%
    final discountPercent = (5 + (id.hashCode % 10)).toDouble();
    final discount = (subtotal * discountPercent / 100).roundToDouble();
    
    // Fixed delivery fee
    const deliveryFee = 40.0;
    
    // Calculate total
    final total = subtotal - discount + deliveryFee;
    
    // Create the order
    return Order(
      id: id,
      userId: userId,
      items: orderItems,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      couponId: discountPercent > 10 ? 'SAVE15' : null,
      status: useStatus,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 30)),
      deliveryInfo: DeliveryInfo(
        name: 'John Doe',
        phoneNumber: '+91 9876543210',
        addressLine: '123 Main Street, Apartment 4B',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        landmark: 'Near Central Park',
      ),
      paymentInfo: PaymentInfo(
        method: _getRandomPaymentMethod(),
        status: 'completed',
        paymentDate: createdAt,
        transactionId: 'TXN${id.substring(3)}',
      ),
    );
  }
  
  // Helper method to create a dummy order item
  static Map<String, dynamic> _createDummyOrderItem(String productId, int quantity) {
    return {
      'id': productId,
      'quantity': quantity,
    };
  }
  
  // Helper method to get a random payment method
  static String _getRandomPaymentMethod() {
    final methods = ['cash_on_delivery', 'card', 'upi'];
    final index = DateTime.now().millisecondsSinceEpoch % methods.length;
    return methods[index];
  }
  
  // Current order (for demonstration)
  static Order getCurrentDummyOrder(String userId) {
    // Always create a new current order for demo purposes
    final order = _createDummyOrder(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      status: 'processing',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      products: [
        _createDummyOrderItem('fresh_fruits_1', 2),
        _createDummyOrderItem('vegetables_fruits_3', 1),
        _createDummyOrderItem('drinks_juices_2', 2),
        _createDummyOrderItem('ice_cream_5', 1),
        _createDummyOrderItem('cookies_1', 3),
        _createDummyOrderItem('milk_1', 1),
        _createDummyOrderItem('bread_1', 1),
      ],
    );
    
    _currentOrder = order;
    return order;
  }
}
