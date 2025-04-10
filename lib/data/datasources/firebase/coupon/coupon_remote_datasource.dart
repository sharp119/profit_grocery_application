import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../models/coupon_model.dart';

abstract class CouponRemoteDataSource {
  /// Get coupon by code from Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CouponModel> getCouponByCode(String code);

  /// Get coupon by ID from Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CouponModel> getCouponById(String id);

  /// Get all active coupons from Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<List<CouponModel>> getActiveCoupons();

  /// Increment usage count for a coupon in Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CouponModel> incrementCouponUsage(String couponId);
}

class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  final FirebaseDatabase database;
  final FirebaseRemoteConfig remoteConfig;

  CouponRemoteDataSourceImpl({
    required this.database,
    required this.remoteConfig,
  });

  @override
  Future<CouponModel> getCouponByCode(String code) async {
    try {
      final ref = database.ref().child('coupons');
      final query = ref.orderByChild('code').equalTo(code);
      
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        // Extract the first match (codes should be unique)
        final couponData = Map<String, dynamic>.from(
          (snapshot.value as Map).values.first as Map);
        
        // Add the ID from the key
        couponData['id'] = (snapshot.value as Map).keys.first;
        
        return CouponModel.fromJson(couponData);
      } else {
        throw NotFoundException(message: 'Coupon not found with code: $code');
      }
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(message: 'Failed to fetch coupon data: $e');
    }
  }

  @override
  Future<CouponModel> getCouponById(String id) async {
    try {
      final ref = database.ref().child('coupons/$id');
      
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final couponData = Map<String, dynamic>.from(snapshot.value as Map);
        couponData['id'] = id;
        
        return CouponModel.fromJson(couponData);
      } else {
        throw NotFoundException(message: 'Coupon not found with ID: $id');
      }
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(message: 'Failed to fetch coupon data: $e');
    }
  }

  @override
  Future<List<CouponModel>> getActiveCoupons() async {
    try {
      final ref = database.ref().child('coupons');
      final query = ref.orderByChild('isActive').equalTo(true);
      
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final couponsMap = snapshot.value as Map;
        
        final List<CouponModel> coupons = [];
        
        couponsMap.forEach((key, value) {
          final couponData = Map<String, dynamic>.from(value);
          couponData['id'] = key;
          
          coupons.add(CouponModel.fromJson(couponData));
        });
        
        return coupons;
      } else {
        return [];
      }
    } catch (e) {
      throw ServerException(message: 'Failed to fetch active coupons: $e');
    }
  }

  @override
  Future<CouponModel> incrementCouponUsage(String couponId) async {
    try {
      // First get the current coupon data
      final coupon = await getCouponById(couponId);
      
      // Increment usage count
      final newUsageCount = (coupon.usageCount ?? 0) + 1;
      
      // Update the usage count in the database
      final ref = database.ref().child('coupons/$couponId/usageCount');
      await ref.set(newUsageCount);
      
      // Return the updated coupon model
      return coupon.copyWith(
        usageCount: newUsageCount,
      ) as CouponModel;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(message: 'Failed to increment coupon usage: $e');
    }
  }
}