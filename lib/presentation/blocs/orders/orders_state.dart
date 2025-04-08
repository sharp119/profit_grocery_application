import 'package:equatable/equatable.dart';

import '../../../domain/entities/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final bool hasMore;
  final Order? currentOrder;
  final String? currentOrderStatus;
  final DateTime? estimatedDeliveryTime;
  final Map<String, String>? deliveryPersonDetails;

  const OrdersLoaded({
    required this.orders,
    this.hasMore = false,
    this.currentOrder,
    this.currentOrderStatus,
    this.estimatedDeliveryTime,
    this.deliveryPersonDetails,
  });

  @override
  List<Object?> get props => [orders, hasMore, currentOrder, currentOrderStatus, estimatedDeliveryTime, deliveryPersonDetails];

  OrdersLoaded copyWith({
    List<Order>? orders,
    bool? hasMore,
    Order? currentOrder,
    String? currentOrderStatus,
    DateTime? estimatedDeliveryTime,
    Map<String, String>? deliveryPersonDetails,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentOrder: currentOrder ?? this.currentOrder,
      currentOrderStatus: currentOrderStatus ?? this.currentOrderStatus,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryPersonDetails: deliveryPersonDetails ?? this.deliveryPersonDetails,
    );
  }
}

class OrderDetailsLoaded extends OrdersState {
  final Order order;

  const OrderDetailsLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderCancelled extends OrdersState {
  final Order order;

  const OrderCancelled({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError({required this.message});

  @override
  List<Object?> get props => [message];
}
