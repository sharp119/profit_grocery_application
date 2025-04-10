import 'package:dartz/dartz.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/entities/coupon.dart';
import '../../../domain/repositories/coupon_repository.dart';
import '../../datasources/firebase/coupon/coupon_remote_datasource.dart';

class CouponRepositoryImpl implements CouponRepository {
  final CouponRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final FirebaseRemoteConfig remoteConfig;

  CouponRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.remoteConfig,
  });

  @override
  Future<Either<Failure, Coupon>> getCouponByCode(String code) async {
    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.getCouponByCode(code);
        
        // Validate if coupon is actually valid
        if (!coupon.isValid()) {
          return Left(CouponFailure(message: 'This coupon has expired or is not active.'));
        }
        
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(CouponFailure(message: 'Invalid coupon code. Please try a different one.'));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Coupon>> getCouponById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.getCouponById(id);
        
        // Validate if coupon is actually valid
        if (!coupon.isValid()) {
          return Left(CouponFailure(message: 'This coupon has expired or is not active.'));
        }
        
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(CouponFailure(message: 'Coupon not found.'));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getActiveCoupons() async {
    if (await networkInfo.isConnected) {
      try {
        final coupons = await remoteDataSource.getActiveCoupons();
        
        // Filter out any invalid coupons (additional validation)
        final validCoupons = coupons.where((coupon) => coupon.isValid()).toList();
        
        return Right(validCoupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
  
  @override
  Future<Either<Failure, Coupon>> validateCoupon({
    required String code,
    required double cartTotal,
    required List<String> productIds,
  }) async {
    if (code.isEmpty) {
      return Left(CouponFailure(message: 'Please enter a coupon code.'));
    }

    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.getCouponByCode(code);
        
        // Check if coupon is valid
        if (!coupon.isValid()) {
          return Left(CouponFailure(message: 'This coupon has expired or is not active.'));
        }
        
        // Check minimum purchase requirement if it exists
        if (coupon.minPurchase != null && cartTotal < coupon.minPurchase!) {
          final formattedMinPurchase = coupon.minPurchase!.toStringAsFixed(2);
          return Left(CouponFailure(
            message: 'This coupon requires a minimum purchase of ₹$formattedMinPurchase.'
          ));
        }
        
        // Check if coupon is applicable to the products in cart (if specified)
        if (coupon.applicableProductIds != null && coupon.applicableProductIds!.isNotEmpty) {
          bool isApplicable = false;
          
          for (final productId in productIds) {
            if (coupon.isApplicableToProduct(productId)) {
              isApplicable = true;
              break;
            }
          }
          
          if (!isApplicable) {
            return Left(CouponFailure(
              message: 'This coupon is not applicable to any items in your cart.'
            ));
          }
        }
        
        // All validations passed
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(CouponFailure(message: 'Invalid coupon code. Please try a different one.'));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Coupon>> incrementCouponUsage(String couponId) async {
    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.incrementCouponUsage(couponId);
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(CouponFailure(message: 'Coupon not found.'));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  // Additional method to validate a coupon based on its code, cart total, and product IDs
  // Future<Either<Failure, Coupon>> validateCoupon({
  //   required String code,
  //   required double cartTotal,
  //   required List<String> productIds,
  // }) async {
  //   if (code.isEmpty) {
  //     return Left(CouponFailure(message: 'Please enter a coupon code.'));
  //   }

  //   if (await networkInfo.isConnected) {
  //     try {
  //       final coupon = await remoteDataSource.getCouponByCode(code);
        
  //       // Check if coupon is valid
  //       if (!coupon.isValid()) {
  //         return Left(CouponFailure(message: 'This coupon has expired or is not active.'));
  //       }
        
  //       // Check minimum purchase requirement if it exists
  //       if (coupon.minPurchase != null && cartTotal < coupon.minPurchase!) {
  //         final formattedMinPurchase = coupon.minPurchase!.toStringAsFixed(2);
  //         return Left(CouponFailure(
  //           message: 'This coupon requires a minimum purchase of ₹$formattedMinPurchase.'
  //         ));
  //       }
        
  //       // Check if coupon is applicable to the products in cart (if specified)
  //       if (coupon.applicableProductIds != null && coupon.applicableProductIds!.isNotEmpty) {
  //         bool isApplicable = false;
          
  //         for (final productId in productIds) {
  //           if (coupon.isApplicableToProduct(productId)) {
  //             isApplicable = true;
  //             break;
  //           }
  //         }
          
  //         if (!isApplicable) {
  //           return Left(CouponFailure(
  //             message: 'This coupon is not applicable to any items in your cart.'
  //           ));
  //         }
  //       }
        
  //       // All validations passed
  //       return Right(coupon);
  //     } on ServerException catch (e) {
  //       return Left(ServerFailure(message: e.message));
  //     } on NotFoundException catch (e) {
  //       return Left(CouponFailure(message: 'Invalid coupon code. Please try a different one.'));
  //     }
  //   } else {
  //     return Left(NetworkFailure());
  //   }
  // }
}