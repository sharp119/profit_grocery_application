import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? couponId;
  final String status; // 'new', 'processing', 'shipped', 'delivered', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeliveryInfo deliveryInfo;
  final PaymentInfo paymentInfo;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    this.couponId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deliveryInfo,
    required this.paymentInfo,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        subtotal,
        discount,
        deliveryFee,
        total,
        couponId,
        status,
        createdAt,
        updatedAt,
        deliveryInfo,
        paymentInfo,
      ];
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double total;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.total,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        price,
        quantity,
        total,
      ];
}

class DeliveryInfo extends Equatable {
  final String name;
  final String phoneNumber;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final String? deliveryInstructions;

  const DeliveryInfo({
    required this.name,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.deliveryInstructions,
  });

  @override
  List<Object?> get props => [
        name,
        phoneNumber,
        addressLine,
        city,
        state,
        pincode,
        landmark,
        deliveryInstructions,
      ];
}

class PaymentInfo extends Equatable {
  final String method; // 'cash_on_delivery', 'card', 'upi'
  final String status; // 'pending', 'completed', 'failed'
  final DateTime? paymentDate;
  final String? transactionId;

  const PaymentInfo({
    required this.method,
    required this.status,
    this.paymentDate,
    this.transactionId,
  });

  @override
  List<Object?> get props => [
        method,
        status,
        paymentDate,
        transactionId,
      ];
}