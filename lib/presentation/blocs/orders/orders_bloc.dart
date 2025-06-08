// lib/presentation/blocs/orders/orders_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/domain/usecases/order/get_orders_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase;

  OrdersBloc({required GetOrdersUseCase getOrdersUseCase})
      : _getOrdersUseCase = getOrdersUseCase,
        super(const OrdersState()) {
    on<LoadOrders>(_onLoadOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(status: OrdersStatus.loading));
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);

      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: OrdersStatus.error,
          errorMessage: 'User not authenticated. Please log in.',
        ));
        return;
      }

      final orders = await _getOrdersUseCase.call(userId, limit: event.limit);
      
      // Print orders to console as requested
      print('--- Fetched Orders ---');
      if (orders.isEmpty) {
        print('No orders found for user: $userId');
      } else {
        for (var order in orders) {
          print('Order ID: ${order.id}');
          print('  Status: ${order.status}');
          print('  Total: ₹${order.pricingSummary.grandTotal.toStringAsFixed(2)}');
          print('  Items: ${order.items.map((item) => '${item.name} x${item.quantity}').join(', ')}');
          print('  Order Date: ${order.orderTimestamp.toDate()}');
          print('--------------------');
        }
      }

      emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: orders,
      ));
    } catch (e) {
      print('OrdersBloc Error: $e');
      emit(state.copyWith(
        status: OrdersStatus.error,
        errorMessage: 'Failed to load orders: $e',
      ));
    }
  }
}