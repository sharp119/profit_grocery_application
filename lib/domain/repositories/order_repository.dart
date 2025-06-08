// lib/domain/repositories/order_repository.dart
import 'package:profit_grocery_application/domain/entities/order.dart';

abstract class OrderRepository {
  /// Creates a new order and returns the unique order ID.
  Future<String> createOrder(OrderEntity order);

  Future<List<OrderEntity>> getOrders(String userId, {int limit = 5}); // For fetching orders later
  // Future<OrderEntity?> getOrderDetails(String userId, String orderId); // For fetching a specific order later
}