import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../models/coupon_model.dart';
import '../../../samples/sample_coupons.dart';
import '../../../../domain/entities/coupon_enums.dart';

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
  
  /// Upload sample coupons to Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<bool> uploadSampleCoupons();
  
  /// Upload sample coupons to Firestore.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<bool> uploadSampleCouponsToFirestore();
}

class CouponRemoteDataSourceImpl implements CouponRemoteDataSource {
  final FirebaseDatabase database;
  final FirebaseRemoteConfig remoteConfig;
  final FirebaseFirestore? firestore;

  CouponRemoteDataSourceImpl({
    required this.database,
    required this.remoteConfig,
    this.firestore,
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
  
  @override
  Future<bool> uploadSampleCoupons() async {
    try {
      // Import the sample coupons
      final sampleCoupons = getSampleCoupons();
      
      // Reference to the coupons node in Firebase
      final ref = database.ref().child('coupons');
      
      // Convert sample coupons to CouponModel and upload them
      for (final sample in sampleCoupons) {
        // Create a coupon model from the sample
        final couponModel = CouponModel(
          id: sample.id,
          code: sample.code,
          type: _getCouponTypeFromString(sample.type),
          value: sample.value,
          minPurchase: sample.minPurchase,
          startDate: sample.startDate,
          endDate: sample.endDate,
          isActive: sample.isActive,
          usageLimit: sample.usageLimit,
          usageCount: 0,
          applicableProductIds: sample.applicableProductIds,
          applicableCategories: sample.applicableCategories,
          description: sample.description,
          freeProductId: sample.freeProductId,
          conditions: sample.conditions,
        );
        
        // Upload to Firebase
        await ref.child(sample.id).set(couponModel.toJson());
      }
      
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to upload sample coupons to RTD: $e');
    }
  }
  
  @override
  Future<bool> uploadSampleCouponsToFirestore() async {
    try {
      // Check if Firestore is available
      if (firestore == null) {
        throw ServerException(message: 'Firestore instance not provided');
      }
      
      // Import the sample coupons
      final sampleCoupons = getSampleCoupons();
      
      // Reference to the coupons collection in Firestore
      final collectionRef = firestore!.collection('coupons');
      
      // Convert sample coupons to CouponModel and upload them
      for (final sample in sampleCoupons) {
        // Create a coupon model from the sample
        final couponModel = CouponModel(
          id: sample.id,
          code: sample.code,
          type: _getCouponTypeFromString(sample.type),
          value: sample.value,
          minPurchase: sample.minPurchase,
          startDate: sample.startDate,
          endDate: sample.endDate,
          isActive: sample.isActive,
          usageLimit: sample.usageLimit,
          usageCount: 0,
          applicableProductIds: sample.applicableProductIds,
          applicableCategories: sample.applicableCategories,
          description: sample.description,
          freeProductId: sample.freeProductId,
          conditions: sample.conditions,
        );
        
        // Upload to Firestore - use the ID as the document ID
        await collectionRef.doc(sample.id).set(couponModel.toJson());
      }
      
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to upload sample coupons to Firestore: $e');
    }
  }
  
  // Helper method to convert string to CouponType enum
  CouponType _getCouponTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'percentage':
        return CouponType.percentage;
      case 'fixed':
      case 'fixed_amount':
      case 'fixedamount':
        return CouponType.fixedAmount;
      case 'free_delivery':
      case 'freedelivery':
        return CouponType.freeDelivery;
      case 'buy_one_get_one':
      case 'buyonegetone':
      case 'bogo':
        return CouponType.buyOneGetOne;
      case 'free_product':
      case 'freeproduct':
        return CouponType.freeProduct;
      case 'conditional':
        return CouponType.conditional;
      default:
        return CouponType.percentage;
    }
  }
}