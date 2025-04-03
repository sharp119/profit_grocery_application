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
}