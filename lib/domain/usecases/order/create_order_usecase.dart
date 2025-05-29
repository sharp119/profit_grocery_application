// lib/domain/usecases/create_order_usecase.dart
import 'package:profit_grocery_application/domain/entities/order.dart';
import 'package:profit_grocery_application/domain/repositories/order_repository.dart';

class CreateOrderUsecase {
  final OrderRepository orderRepository;

  CreateOrderUsecase(this.orderRepository);

  /// Executes the order creation process.
  Future<String> call(OrderEntity order) async {
    // Add any business validation for the order before saving if needed
    // For example, check if items list is not empty, etc.
    if (order.items.isEmpty) {
      throw ArgumentError('Order must contain at least one item.');
    }
    if (order.userId.isEmpty) {
      throw ArgumentError('User ID must be provided for the order.');
    }
    return await orderRepository.createOrder(order);
  }
}