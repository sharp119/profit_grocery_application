import 'package:profit_grocery_application/domain/entities/order.dart';

abstract class OrderRepository {
  Future<String> createOrder(OrderEntity order);
  // You can add other methods like:
  // Future<List<OrderEntity>> getOrders(String userId);
  // Future<OrderEntity?> getOrderDetails(String userId, String orderId);
}