import 'package:equatable/equatable.dart';

enum CheckoutStatus {
  initial,
  loading,
  loaded,
  placingOrder,
  orderSuccess,
  error,
}

class UserAddress {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String pincode;
  final String type; // home, work, other
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.pincode,
    required this.type,
    this.isDefault = false,
  });
}

class PaymentMethod {
  final int id;
  final String name;
  final String icon;
  final bool isAvailable;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });
}

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final List<UserAddress> addresses;
  final UserAddress? selectedAddress;
  final List<PaymentMethod> paymentMethods;
  final int selectedPaymentMethodId;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final int itemCount;
  final String? couponCode;
  final String? orderId;
  final String? errorMessage;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddress,
    this.paymentMethods = const [],
    this.selectedPaymentMethodId = 0,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
    this.total = 0.0,
    this.itemCount = 0,
    this.couponCode,
    this.orderId,
    this.errorMessage,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<UserAddress>? addresses,
    UserAddress? selectedAddress,
    List<PaymentMethod>? paymentMethods,
    int? selectedPaymentMethodId,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? total,
    int? itemCount,
    String? couponCode,
    String? orderId,
    String? errorMessage,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentMethodId: selectedPaymentMethodId ?? this.selectedPaymentMethodId,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      couponCode: couponCode ?? this.couponCode,
      orderId: orderId ?? this.orderId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    addresses,
    selectedAddress,
    paymentMethods,
    selectedPaymentMethodId,
    subtotal,
    discount,
    deliveryFee,
    total,
    itemCount,
    couponCode,
    orderId,
    errorMessage,
  ];
}