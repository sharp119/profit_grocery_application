import 'package:dartz/dartz.dart' hide Order;

import '../../../core/errors/failures.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../inventory/order_inventory.dart';

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<Either<Failure, List<Order>>> getUserOrders({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    try {
      // Fetch dummy orders from the inventory
      final orders = OrderInventory.getDummyOrders(userId);
      
      // Apply pagination if provided
      if (offset != null && limit != null) {
        final end = (offset + limit) > orders.length ? orders.length : offset + limit;
        final paginatedOrders = orders.sublist(offset, end);
        return Right(paginatedOrders);
      }
      
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById({
    required String userId,
    required String orderId,
  }) async {
    try {
      // Fetch dummy orders from the inventory
      final orders = OrderInventory.getDummyOrders(userId);
      
      // Find the order with the matching ID
      final order = orders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Order>> placeOrder({
    required String userId,
    required Cart cart,
    required DeliveryInfo deliveryInfo,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      // In a real implementation, this would save the order to Firestore
      // For now, just return a dummy order
      final now = DateTime.now();
      final order = Order(
        id: 'order_${now.millisecondsSinceEpoch}',
        userId: userId,
        items: cart.items.map((item) => OrderItem(
          productId: item.productId,
          productName: item.name,
          productImage: item.image,
          price: item.price,
          quantity: item.quantity,
          total: item.price * item.quantity,
        )).toList(),
        subtotal: cart.subtotal,
        discount: cart.discount,
        deliveryFee: 40.0, // Fixed delivery fee
        total: cart.total + 40.0, // Add delivery fee to total
        couponId: cart.appliedCouponId,
        status: 'new',
        createdAt: now,
        updatedAt: now,
        deliveryInfo: deliveryInfo,
        paymentInfo: paymentInfo,
      );
      
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to place order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Order>> cancelOrder({
    required String userId,
    required String orderId,
  }) async {
    try {
      // In a real implementation, this would update the order status in Firestore
      // For now, just return a dummy order with canceled status
      
      // Fetch the order
      final orderResult = await getOrderById(userId: userId, orderId: orderId);
      
      return orderResult.fold(
        (failure) => Left(failure),
        (order) {
          // Create a new order with canceled status
          final canceledOrder = Order(
            id: order.id,
            userId: order.userId,
            items: order.items,
            subtotal: order.subtotal,
            discount: order.discount,
            deliveryFee: order.deliveryFee,
            total: order.total,
            couponId: order.couponId,
            status: 'cancelled',
            createdAt: order.createdAt,
            updatedAt: DateTime.now(),
            deliveryInfo: order.deliveryInfo,
            paymentInfo: order.paymentInfo,
          );
          
          return Right(canceledOrder);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to cancel order: ${e.toString()}'));
    }
  }
}
