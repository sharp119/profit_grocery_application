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
  final String? nutritionalInfo;
  final String? ingredients;
  final String? sku;
  final String? productType;
  final int? quantity;
  final String? categoryGroup;
  final bool hasDiscount; // Explicit flag from RTDB

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
    this.nutritionalInfo,
    this.ingredients,
    this.sku,
    this.productType,
    this.quantity,
    this.categoryGroup,
    this.hasDiscount = false,
  });

  // Get discount percentage if mrp is available
  double? get discountPercentage {
    if (mrp != null && mrp! > price) {
      return ((mrp! - price) / mrp! * 100).roundToDouble();
    }
    return null;
  }

  // Check if the product has a calculated discount based on price difference
  bool get hasCalculatedDiscount => discountPercentage != null && discountPercentage! > 0;

  /// Create a copy of this Product with some fields changed
  Product copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    double? price,
    double? mrp,
    bool? inStock,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    List<String>? tags,
    bool? isFeatured,
    bool? isActive,
    String? weight,
    String? brand,
    String? sellerName,
    double? rating,
    int? reviewCount,
    String? nutritionalInfo,
    String? ingredients,
    String? sku,
    String? productType,
    int? quantity,
    String? categoryGroup,
    bool? hasDiscount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      inStock: inStock ?? this.inStock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      weight: weight ?? this.weight,
      brand: brand ?? this.brand,
      sellerName: sellerName ?? this.sellerName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      ingredients: ingredients ?? this.ingredients,
      sku: sku ?? this.sku,
      productType: productType ?? this.productType,
      quantity: quantity ?? this.quantity,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      hasDiscount: hasDiscount ?? this.hasDiscount,
    );
  }

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
        nutritionalInfo,
        ingredients,
        sku,
        productType,
        quantity,
        categoryGroup,
        hasDiscount,
      ];
}