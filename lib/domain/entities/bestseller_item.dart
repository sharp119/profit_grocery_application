import 'package:equatable/equatable.dart';
import '../../services/discount/discount_service.dart';

/// Represents a bestseller item with discount information
/// Used to track bestseller-specific discounts separate from regular product discounts
class BestsellerItem extends Equatable {
  final String productId;
  final int rank;
  String? discountType;
  double? discountValue;
  
  BestsellerItem({
    required this.productId,
    required this.rank,
    this.discountType,
    this.discountValue,
  });
  
  /// Check if this bestseller has a special discount
  bool get hasSpecialDiscount => DiscountService.hasDiscount(
    discountType: discountType,
    discountValue: discountValue,
    productId: productId,
  );
  
  /// Calculate the discounted price based on original price
  double getDiscountedPrice(double originalPrice) {
    return DiscountService.calculateFinalPrice(
      originalPrice: originalPrice,
      discountType: discountType,
      discountValue: discountValue,
      productId: productId,
    );
  }
  
  @override
  List<Object?> get props => [
    productId,
    rank,
    discountType,
    discountValue,
  ];
  
  @override
  String toString() => 'BestsellerItem(productId: $productId, rank: $rank, '
      'discountType: $discountType, discountValue: $discountValue)';
}