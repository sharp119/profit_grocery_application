import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserOrders extends OrdersEvent {
  final String userId;
  final int? limit;
  final int? offset;

  const LoadUserOrders({
    required this.userId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}

class LoadCurrentOrder extends OrdersEvent {
  final String userId;

  const LoadCurrentOrder({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadOrderDetails extends OrdersEvent {
  final String userId;
  final String orderId;

  const LoadOrderDetails({
    required this.userId,
    required this.orderId,
  });

  @override
  List<Object?> get props => [userId, orderId];
}

class CancelOrder extends OrdersEvent {
  final String userId;
  final String orderId;

  const CancelOrder({
    required this.userId,
    required this.orderId,
  });

  @override
  List<Object?> get props => [userId, orderId];
}

class RefreshOrders extends OrdersEvent {
  final String userId;

  const RefreshOrders({required this.userId});

  @override
  List<Object?> get props => [userId];
}
