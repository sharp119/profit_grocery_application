import '../../domain/entities/coupon.dart';

class CouponModel extends Coupon {
  const CouponModel({
    required String id,
    required String code,
    required String type,
    required double value,
    double? minPurchase,
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
    return CouponModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'percentage',
      value: (json['value'] ?? 0.0).toDouble(),
      minPurchase: json['minPurchase'] != null ? (json['minPurchase']).toDouble() : null,
      startDate: json['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['endDate']) : null,
      isActive: json['isActive'] ?? false,
      usageLimit: json['usageLimit'],
      usageCount: json['usageCount'] ?? 0,
      applicableProductIds: json['applicableProductIds'] != null 
          ? List<String>.from(json['applicableProductIds']) 
          : null,
      applicableCategories: json['applicableCategories'] != null 
          ? List<String>.from(json['applicableCategories']) 
          : null,
      description: json['description'],
      freeProductId: json['freeProductId'],
      conditions: json['conditions'],
    );
  }

  // Convert CouponModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'minPurchase': minPurchase,
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
    String? type,
    double? value,
    double? minPurchase,
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
}