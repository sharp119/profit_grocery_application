import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String image;
  final String? description;
  final double price;
  final double? mrp; // Market Retail Price (original price before discount)
  final bool inStock;
  final String categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final List<String> tags;
  final bool isFeatured;
  final bool isActive;
  final String? weight;
  final String? brand;
  final String? sellerName;
  final double? rating;
  final int? reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    required this.price,
    this.mrp,
    this.inStock = true,
    required this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.tags = const [],
    this.isFeatured = false,
    this.isActive = true,
    this.weight,
    this.brand,
    this.sellerName,
    this.rating,
    this.reviewCount,
  });

  // Get discount percentage if mrp is available
  double? get discountPercentage {
    if (mrp != null && mrp! > price) {
      return ((mrp! - price) / mrp! * 100).roundToDouble();
    }
    return null;
  }

  // Check if the product has a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        description,
        price,
        mrp,
        inStock,
        categoryId,
        categoryName,
        subcategoryId,
        tags,
        isFeatured,
        isActive,
        weight,
        brand,
        sellerName,
        rating,
        reviewCount,
      ];
}