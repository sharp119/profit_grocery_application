import 'package:equatable/equatable.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoupons extends CouponEvent {
  final String? deepLinkCoupon;

  const LoadCoupons([this.deepLinkCoupon]);

  @override
  List<Object?> get props => [deepLinkCoupon];
}

class ValidateCoupon extends CouponEvent {
  final String code;

  const ValidateCoupon(this.code);

  @override
  List<Object?> get props => [code];
}

class ValidateDeepLinkCoupon extends CouponEvent {
  final String code;

  const ValidateDeepLinkCoupon(this.code);

  @override
  List<Object?> get props => [code];
}

class ClearDeepLinkCoupon extends CouponEvent {
  const ClearDeepLinkCoupon();
}

class UploadSampleCoupons extends CouponEvent {
  const UploadSampleCoupons();
}

class UploadSampleCouponsToFirestore extends CouponEvent {
  const UploadSampleCouponsToFirestore();
}