import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/inventory/order_inventory.dart';
import '../../../domain/repositories/order_repository.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;

  OrdersBloc({required this.orderRepository}) : super(OrdersInitial()) {
    on<LoadUserOrders>(_onLoadUserOrders);
    on<LoadCurrentOrder>(_onLoadCurrentOrder);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<CancelOrder>(_onCancelOrder);
    on<RefreshOrders>(_onRefreshOrders);
  }

  Future<void> _onLoadUserOrders(
    LoadUserOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());

    final result = await orderRepository.getUserOrders(
      userId: event.userId,
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) => emit(OrdersError(message: failure.message)),
      (orders) {
        // Check if there are more orders that can be loaded
        final hasMore = event.limit != null && orders.length >= event.limit!;
        
        emit(OrdersLoaded(
          orders: orders,
          hasMore: hasMore,
        ));
      },
    );
  }

  Future<void> _onLoadCurrentOrder(
    LoadCurrentOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());

    try {
      // Always create a current order for demo purposes
      final currentOrder = OrderInventory.getCurrentDummyOrder(event.userId);
      
      // Force out_for_delivery for demo
      final currentOrderStatus = 'out_for_delivery';
      
      // Get estimated delivery time
      final estimatedDeliveryTime = OrderInventory.getEstimatedDeliveryTime();
      
      // Get delivery person details
      final deliveryPersonDetails = OrderInventory.getDeliveryPersonDetails();
      
      emit(OrdersLoaded(
        orders: [], // We'll load past orders separately
        hasMore: false,
        currentOrder: currentOrder,
        currentOrderStatus: currentOrderStatus,
        estimatedDeliveryTime: estimatedDeliveryTime,
        deliveryPersonDetails: deliveryPersonDetails,
      ));
    } catch (e) {
      emit(OrdersError(message: 'Failed to load current order: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());

    final result = await orderRepository.getOrderById(
      userId: event.userId,
      orderId: event.orderId,
    );

    result.fold(
      (failure) => emit(OrdersError(message: failure.message)),
      (order) => emit(OrderDetailsLoaded(order: order)),
    );
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());

    final result = await orderRepository.cancelOrder(
      userId: event.userId,
      orderId: event.orderId,
    );

    result.fold(
      (failure) => emit(OrdersError(message: failure.message)),
      (order) => emit(OrderCancelled(order: order)),
    );
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    
    try {
      // Get past orders
      final ordersResult = await orderRepository.getUserOrders(
        userId: event.userId,
      );
      
      // Get current order
      final currentOrder = OrderInventory.getCurrentDummyOrder(event.userId);
      
      // Force out_for_delivery for demo
      const currentOrderStatus = 'out_for_delivery';
      
      // Get delivery details
      final estimatedDeliveryTime = OrderInventory.getEstimatedDeliveryTime();
      final deliveryPersonDetails = OrderInventory.getDeliveryPersonDetails();
      
      ordersResult.fold(
        (failure) => emit(OrdersError(message: failure.message)),
        (orders) => emit(OrdersLoaded(
          orders: orders,
          hasMore: false,
          currentOrder: currentOrder,
          currentOrderStatus: currentOrderStatus,
          estimatedDeliveryTime: estimatedDeliveryTime,
          deliveryPersonDetails: deliveryPersonDetails,
        )),
      );
    } catch (e) {
      emit(OrdersError(message: 'Failed to refresh orders: ${e.toString()}'));
    }
  }
}
