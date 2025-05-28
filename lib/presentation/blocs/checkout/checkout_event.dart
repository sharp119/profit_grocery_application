import 'package:equatable/equatable.dart';

import 'checkout_state.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadCheckout extends CheckoutEvent {
  const LoadCheckout();
}

class SelectAddress extends CheckoutEvent {
  final String addressId;

  const SelectAddress(this.addressId);

  @override
  List<Object?> get props => [addressId];
}

class SelectPaymentMethod extends CheckoutEvent {
  final int paymentMethodId;

  const SelectPaymentMethod(this.paymentMethodId);

  @override
  List<Object?> get props => [paymentMethodId];
}

class ApplyCouponCO extends CheckoutEvent {
  final String code;

  const ApplyCouponCO(this.code);

  @override
  List<Object?> get props => [code];
}

class RemoveCoupon extends CheckoutEvent {
  const RemoveCoupon();
}

class PlaceOrder extends CheckoutEvent {
  const PlaceOrder();
}

class AddAddress extends CheckoutEvent {
  final UserAddress address;

  const AddAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateAddress extends CheckoutEvent {
  final UserAddress address;

  const UpdateAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class DeleteAddress extends CheckoutEvent {
  final String addressId;

  const DeleteAddress(this.addressId);

  @override
  List<Object?> get props => [addressId];
}