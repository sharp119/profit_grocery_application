import '../../domain/entities/coupon.dart';
import '../../domain/entities/coupon_enums.dart';

class CouponModel extends Coupon {
  const CouponModel({
    required String id,
    required String code,
    required CouponType type,
    required double value,
    double? minPurchase,
    double? maxDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
    int? usageLimit,
    int? usageCount,
    List<String>? applicableProductIds,
    List<String>? applicableCategories,
    String? description,
    String? freeProductId,
    Map<String, dynamic>? conditions,
  }) : super(
    id: id,
    code: code,
    type: type,
    value: value,
    minPurchase: minPurchase,
    maxDiscount: maxDiscount,
    startDate: startDate,
    endDate: endDate,
    isActive: isActive,
    usageLimit: usageLimit,
    usageCount: usageCount,
    applicableProductIds: applicableProductIds,
    applicableCategories: applicableCategories,
    description: description,
    freeProductId: freeProductId,
    conditions: conditions,
  );

  // Factory constructor to create a CouponModel from JSON
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    // Convert string type to enum
    final CouponType couponType = _getCouponTypeFromString(json['type']?.toString() ?? 'percentage');
    
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: couponType,
      value: (json['value'] ?? 0.0).toDouble(),
      minPurchase: json['minPurchase'] != null ? (json['minPurchase']).toDouble() : null,
      maxDiscount: json['maxDiscount'] != null ? (json['maxDiscount']).toDouble() : null,
      startDate: json['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int) : null,
      endDate: json['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int) : null,
      isActive: json['isActive'] ?? false,
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      applicableProductIds: json['applicableProductIds'] != null 
          ? List<String>.from(json['applicableProductIds'] as List) 
          : null,
      applicableCategories: json['applicableCategories'] != null 
          ? List<String>.from(json['applicableCategories'] as List) 
          : null,
      description: json['description']?.toString(),
      freeProductId: json['freeProductId']?.toString(),
      conditions: json['conditions'] as Map<String, dynamic>?,
    );
  }

  // Convert CouponModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': _typeToString(type),
      'value': value,
      'minPurchase': minPurchase,
      'maxDiscount': maxDiscount,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'applicableProductIds': applicableProductIds,
      'applicableCategories': applicableCategories,
      'description': description,
      'freeProductId': freeProductId,
      'conditions': conditions,
    };
  }

  // Create a copy of the coupon with updated fields
  CouponModel copyWith({
    String? id,
    String? code,
    CouponType? type,
    double? value,
    double? minPurchase,
    double? maxDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? usageLimit,
    int? usageCount,
    List<String>? applicableProductIds,
    List<String>? applicableCategories,
    String? description,
    String? freeProductId,
    Map<String, dynamic>? conditions,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minPurchase: minPurchase ?? this.minPurchase,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      applicableProductIds: applicableProductIds ?? this.applicableProductIds,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      description: description ?? this.description,
      freeProductId: freeProductId ?? this.freeProductId,
      conditions: conditions ?? this.conditions,
    );
  }
  
  // Helper method to convert string to CouponType enum
  static CouponType _getCouponTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'percentage':
        return CouponType.percentage;
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
  
  // Helper method to convert CouponType enum to string
  static String _typeToString(CouponType type) {
    switch (type) {
      case CouponType.percentage:
        return 'percentage';
      case CouponType.fixedAmount:
        return 'fixed_amount';
      case CouponType.freeDelivery:
        return 'free_delivery';
      case CouponType.buyOneGetOne:
        return 'buy_one_get_one';
      case CouponType.freeProduct:
        return 'free_product';
      case CouponType.conditional:
        return 'conditional';
    }
  }
}