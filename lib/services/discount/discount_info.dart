/// Represents a discount with all necessary information
/// Used to return complete discount details from the discount service
class DiscountInfo {
  final String productId;
  final bool hasDiscount;
  final String? discountType; // 'percentage' or 'flat'
  final double? discountValue;
  final double originalPrice;
  final double finalPrice;
  final String? source; // Where the discount came from: 'bestseller', 'regular', etc.
  
  DiscountInfo({
    required this.productId,
    required this.hasDiscount,
    this.discountType,
    this.discountValue,
    required this.originalPrice,
    required this.finalPrice,
    this.source,
  });
  
  @override
  String toString() => 'DiscountInfo(productId: $productId, '
      'hasDiscount: $hasDiscount, '
      'discountType: $discountType, '
      'discountValue: $discountValue, '
      'originalPrice: $originalPrice, '
      'finalPrice: $finalPrice, '
      'source: $source)';
}