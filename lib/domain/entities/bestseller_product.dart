import 'package:equatable/equatable.dart';
import 'bestseller_item.dart';
import 'product.dart';

/// Combines a Product with BestsellerItem information
/// Allows displaying both product details and bestseller-specific discounts
class BestsellerProduct extends Equatable {
  final Product product;
  final BestsellerItem bestsellerInfo;
  
  const BestsellerProduct({
    required this.product,
    required this.bestsellerInfo,
  });
  
  /// Get product ID
  String get id => product.id;
  
  /// Get product name
  String get name => product.name;
  
  /// Get product image URL
  String get image => product.image;
  
  /// Get original product price
  double get originalPrice => product.price;
  
  /// Get MRP (market retail price) if available
  double? get mrp => product.mrp;
  
  /// Get product stock status
  bool get inStock => product.inStock;
  
  /// Get product weight
  String? get weight => product.weight;
  
  /// Get product description
  String? get description => product.description;
  
  /// Get bestseller rank
  int get rank => bestsellerInfo.rank;
  
  /// Check if bestseller has special discount
  bool get hasSpecialDiscount => bestsellerInfo.hasSpecialDiscount;
  
  /// Get the bestseller discount type (percentage or flat)
  String? get discountType => bestsellerInfo.discountType;
  
  /// Get the bestseller discount value
  double? get discountValue => bestsellerInfo.discountValue;
  
  /// Get final price after applying bestseller discount
  double get finalPrice => hasSpecialDiscount
      ? bestsellerInfo.getDiscountedPrice(product.price)
      : product.price;
  
  /// Get total discount percentage (after applying bestseller discount)
  double get totalDiscountPercentage {
    if (mrp == null || mrp! <= finalPrice) {
      return 0.0;
    }
    return ((mrp! - finalPrice) / mrp! * 100).roundToDouble();
  }
  
  /// Check if the product has any discount (either bestseller or regular)
  bool get hasAnyDiscount => totalDiscountPercentage > 0;
  
  @override
  List<Object?> get props => [
    product,
    bestsellerInfo,
  ];
  
  @override
  String toString() => 'BestsellerProduct(product: ${product.name}, '
      'rank: $rank, finalPrice: $finalPrice)';
}