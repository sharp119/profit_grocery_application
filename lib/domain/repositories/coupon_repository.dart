import 'package:dartz/dartz.dart';

import '../entities/coupon.dart';
import '../../core/errors/failures.dart';

abstract class CouponRepository {
  /// Get coupon by code
  Future<Either<Failure, Coupon>> getCouponByCode(String code);
  
  /// Get coupon by ID
  Future<Either<Failure, Coupon>> getCouponById(String id);
  
  /// Get all active coupons
  Future<Either<Failure, List<Coupon>>> getActiveCoupons();
  
  /// Increment usage count for a coupon
  Future<Either<Failure, Coupon>> incrementCouponUsage(String couponId);
  
  /// Validate coupon based on code, cart total, and product IDs
  Future<Either<Failure, Coupon>> validateCoupon({
    required String code,
    required double cartTotal,
    required List<String> productIds,
  });
  
  /// Upload sample coupons to Firebase
  Future<Either<Failure, bool>> uploadSampleCoupons();
  
  /// Upload sample coupons to Firestore
  Future<Either<Failure, bool>> uploadSampleCouponsToFirestore();
}