import 'package:equatable/equatable.dart';

enum CouponStatus {
  initial,
  loading,
  loaded,
  error,
  deepLinkCouponValid,
  deepLinkCouponInvalid,
  uploading,
  uploadSuccess,
  uploadFailure,
}

class CouponInfo {
  final String code;
  final String discount;
  final String? minOrderValue;
  final String? expiryDate;
  final String description;
  final bool isValid;

  CouponInfo({
    required this.code,
    required this.discount,
    this.minOrderValue,
    this.expiryDate,
    required this.description,
    this.isValid = true,
  });
}

class DeepLinkCouponInfo {
  final String? discount;
  final String? minOrderValue;
  final String? expiryDate;
  final String? description;

  DeepLinkCouponInfo({
    this.discount,
    this.minOrderValue,
    this.expiryDate,
    this.description,
  });
}

class CouponState extends Equatable {
  final CouponStatus status;
  final List<CouponInfo> coupons;
  final String? deepLinkCoupon;
  final DeepLinkCouponInfo? deepLinkCouponInfo;
  final String? errorMessage;

  const CouponState({
    this.status = CouponStatus.initial,
    this.coupons = const [],
    this.deepLinkCoupon,
    this.deepLinkCouponInfo,
    this.errorMessage,
  });

  CouponState copyWith({
    CouponStatus? status,
    List<CouponInfo>? coupons,
    String? deepLinkCoupon,
    DeepLinkCouponInfo? deepLinkCouponInfo,
    String? errorMessage,
  }) {
    return CouponState(
      status: status ?? this.status,
      coupons: coupons ?? this.coupons,
      deepLinkCoupon: deepLinkCoupon ?? this.deepLinkCoupon,
      deepLinkCouponInfo: deepLinkCouponInfo ?? this.deepLinkCouponInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    coupons,
    deepLinkCoupon,
    deepLinkCouponInfo,
    errorMessage,
  ];
}