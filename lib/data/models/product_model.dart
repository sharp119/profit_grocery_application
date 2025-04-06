import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    required super.image,
    super.description,
    required super.price,
    super.mrp,
    super.inStock = true,
    required super.categoryId,
    super.categoryName,
    super.subcategoryId,
    super.tags = const [],
    super.isFeatured = false,
    super.isActive = true,
    super.weight,
    super.brand,
    super.sellerName,
    super.rating,
    super.reviewCount,
  });

  // Factory constructor to create a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      description: json['description'],
      price: json['price'].toDouble(),
      mrp: json['mrp']?.toDouble(),
      inStock: json['inStock'] ?? true,
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      subcategoryId: json['subcategoryId'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      weight: json['weight'],
      brand: json['brand'],
      sellerName: json['sellerName'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }

  // Convert ProductModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'price': price,
      'mrp': mrp,
      'inStock': inStock,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'tags': tags,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'weight': weight,
      'brand': brand,
      'sellerName': sellerName,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
