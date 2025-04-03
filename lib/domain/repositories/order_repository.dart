import 'package:dartz/dartz.dart' hide Order;

import '../entities/order.dart';
import '../entities/cart.dart';
import '../../core/errors/failures.dart';

abstract class OrderRepository {
  /// Get user's orders with optional pagination
  Future<Either<Failure, List<Order>>> getUserOrders({
    required String userId,
    int? limit,
    int? offset,
  });
  
  /// Get order details by ID
  Future<Either<Failure, Order>> getOrderById({
    required String userId,
    required String orderId,
  });
  
  /// Place a new order
  Future<Either<Failure, Order>> placeOrder({
    required String userId,
    required Cart cart,
    required DeliveryInfo deliveryInfo,
    required PaymentInfo paymentInfo,
  });
  
  /// Cancel an order
  Future<Either<Failure, Order>> cancelOrder({
    required String userId,
    required String orderId,
  });
}