// lib/presentation/blocs/orders/orders_event.dart
import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object> get props => [];
}

class LoadOrders extends OrdersEvent {
  final String userId;
  final int limit;

  const LoadOrders({required this.userId, this.limit = 5});

  @override
  List<Object> get props => [userId, limit];
}