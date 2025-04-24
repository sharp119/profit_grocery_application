import 'package:equatable/equatable.dart';
import '../services/discount/discount_calculator.dart';

/// A model representing discount information for a product
/// Used throughout the app for consistent discount representation
class DiscountModel extends Equatable {
  final String productId;
  final String? discountType; // 'percentage' or 'flat'
  final double? discountValue;
  final String? source; // Where the discount came from: 'bestseller', 'regular', 'promo', etc.
  final double originalPrice;
  final double finalPrice;
  
  // Computed properties
  bool get hasDiscount => discountType != null && discountValue != null && discountValue! > 0;
  
  double get discountPercentage => DiscountCalculator.calculateDiscountPercentage(
    originalPrice: originalPrice,
    finalPrice: finalPrice,
  );
  
  double get discountAmount => DiscountCalculator.calculateDiscountAmount(
    originalPrice: originalPrice,
    finalPrice: finalPrice,
  );
  
  String get formattedDiscount => DiscountCalculator.formatDiscountForDisplay(
    discountType: discountType,
    discountValue: discountValue,
  );
  
  const DiscountModel({
    required this.productId,
    this.discountType,
    this.discountValue,
    this.source,
    required this.originalPrice,
    required this.finalPrice,
  });
  
  /// Create a model instance for a product with no discount
  factory DiscountModel.noDiscount({
    required String productId,
    required double price,
  }) {
    return DiscountModel(
      productId: productId,
      originalPrice: price,
      finalPrice: price,
    );
  }
  
  /// Create a model with percentage discount
  factory DiscountModel.percentage({
    required String productId,
    required double originalPrice,
    required double percentageValue,
    String source = 'manual',
  }) {
    final finalPrice = DiscountCalculator.calculatePercentageDiscount(
      originalPrice: originalPrice,
      percentageValue: percentageValue,
    );
    
    return DiscountModel(
      productId: productId,
      discountType: 'percentage',
      discountValue: percentageValue,
      source: source,
      originalPrice: originalPrice,
      finalPrice: finalPrice,
    );
  }
  
  /// Create a model with flat discount
  factory DiscountModel.flat({
    required String productId,
    required double originalPrice,
    required double flatValue,
    String source = 'manual',
  }) {
    final finalPrice = DiscountCalculator.calculateFlatDiscount(
      originalPrice: originalPrice,
      flatValue: flatValue,
    );
    
    return DiscountModel(
      productId: productId,
      discountType: 'flat',
      discountValue: flatValue,
      source: source,
      originalPrice: originalPrice,
      finalPrice: finalPrice,
    );
  }
  
  /// Copy this discount model with some changes
  DiscountModel copyWith({
    String? productId,
    String? discountType,
    double? discountValue,
    String? source,
    double? originalPrice,
    double? finalPrice,
  }) {
    return DiscountModel(
      productId: productId ?? this.productId,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      source: source ?? this.source,
      originalPrice: originalPrice ?? this.originalPrice,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }
  
  @override
  List<Object?> get props => [
    productId,
    discountType,
    discountValue,
    source,
    originalPrice,
    finalPrice,
  ];
  
  @override
  String toString() => 'DiscountModel('
      'productId: $productId, '
      'discountType: $discountType, '
      'discountValue: $discountValue, '
      'source: $source, '
      'originalPrice: $originalPrice, '
      'finalPrice: $finalPrice)';
}