// lib/domain/usecases/order/get_orders_usecase.dart
import 'package:profit_grocery_application/domain/entities/order.dart';
import 'package:profit_grocery_application/domain/repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepository _orderRepository;

  GetOrdersUseCase(this._orderRepository);

  Future<List<OrderEntity>> call(String userId, {int limit = 5}) async {
    return await _orderRepository.getOrders(userId, limit: limit);
  }
}