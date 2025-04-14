import 'package:equatable/equatable.dart';

import 'coupon_enums.dart';

class Coupon extends Equatable {
  final String id;
  final String code;
  final CouponType type;
  final double value; // Discount value or percentage
  final double? minPurchase; // Minimum purchase requirement
  final double? maxDiscount; // Maximum discount amount (for percentage coupons)
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int? usageLimit; // Maximum usage count
  final int? usageCount; // Current usage count
  final List<String>? applicableProductIds; // Products this coupon can be applied to
  final List<String>? applicableCategories; // Categories this coupon can be applied to
  final String? description;
  final String? freeProductId; // For free product coupons
  final Map<String, dynamic>? conditions; // For conditional coupons

  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minPurchase,
    this.maxDiscount,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.usageLimit,
    this.usageCount = 0,
    this.applicableProductIds,
    this.applicableCategories,
    this.description,
    this.freeProductId,
    this.conditions,
  });

  // Check if coupon is valid
  bool isValid() {
    final now = DateTime.now();
    
    // Check if coupon is active
    if (!isActive) return false;
    
    // Check if coupon has a start date and it's in the future
    if (startDate != null && startDate!.isAfter(now)) return false;
    
    // Check if coupon has an end date and it's in the past
    if (endDate != null && endDate!.isBefore(now)) return false;
    
    // Check if coupon has reached its usage limit
    if (usageLimit != null && usageCount != null && usageCount! >= usageLimit!) {
      return false;
    }
    
    return true;
  }

  // Check if coupon is applicable to a specific product
  bool isApplicableToProduct(String productId) {
    if (applicableProductIds == null || applicableProductIds!.isEmpty) {
      return true; // No product restrictions
    }
    
    return applicableProductIds!.contains(productId);
  }

  // Check if coupon is applicable to a specific category
  bool isApplicableToCategory(String categoryId) {
    if (applicableCategories == null || applicableCategories!.isEmpty) {
      return true; // No category restrictions
    }
    
    return applicableCategories!.contains(categoryId);
  }

  @override
  List<Object?> get props => [
    id,
    code,
    type,
    value,
    minPurchase,
    maxDiscount,
    startDate,
    endDate,
    isActive,
    usageLimit,
    usageCount,
    applicableProductIds,
    applicableCategories,
    description,
    freeProductId,
    conditions,
  ];
}