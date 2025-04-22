import 'package:equatable/equatable.dart';

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
  bool get hasSpecialDiscount => 
    discountType != null && 
    discountValue != null && 
    discountValue! > 0;
  
  /// Calculate the discounted price based on original price
  double getDiscountedPrice(double originalPrice) {
    if (!hasSpecialDiscount) return originalPrice;
    
    if (discountType == 'percentage') {
      final discount = originalPrice * (discountValue! / 100);
      return originalPrice - discount;
    } else if (discountType == 'flat') {
      return originalPrice - discountValue!;
    }
    
    return originalPrice;
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