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
  final Map<String, dynamic>? customProperties;

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
    this.customProperties,
  });

  // Factory constructor to create Product from RTDB data
  factory Product.fromRTDB(String id, Map<String, dynamic> data) {
    // Helper to safely cast to double
    double? _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Helper to safely cast to int
    int? _toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final int stockQuantity = _toInt(data['quantity']) ?? 0;
    final bool determinedInStock = (data['inStock'] as bool?) ?? (stockQuantity > 0);

    return Product(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Product',
      // Assuming image URL might be under 'image', 'imageUrl', or 'image_url' in RTDB
      image: data['image_url'] as String? ?? data['image'] as String? ?? '',
      description: data['description'] as String?,
      price: _toDouble(data['price']) ?? 0.0,
      mrp: _toDouble(data['mrp']),
      inStock: determinedInStock,
      categoryId: data['categoryId'] as String? ?? data['categoryID'] as String? ?? '', // Handle variations
      categoryName: data['categoryName'] as String?,
      subcategoryId: data['subcategoryId'] as String? ?? data['subcategoryID'] as String?,
      tags: (data['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      isFeatured: data['isFeatured'] as bool? ?? data['featured'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? data['active'] as bool? ?? true,
      weight: data['weight'] as String?,
      brand: data['brand'] as String? ?? data['brandName'] as String?,
      sellerName: data['sellerName'] as String?,
      rating: _toDouble(data['rating']),
      reviewCount: _toInt(data['reviewCount']),
      nutritionalInfo: data['nutritionalInfo'] as String?,
      ingredients: data['ingredients'] as String?,
      sku: data['sku'] as String?,
      productType: data['productType'] as String?,
      quantity: stockQuantity, // Available stock
      categoryGroup: data['categoryGroup'] as String?,
      customProperties: data['customProperties'] as Map<String, dynamic>?,
    );
  }

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
        nutritionalInfo,
        ingredients,
        sku,
        productType,
        quantity,
        categoryGroup,
        customProperties,
      ];
}