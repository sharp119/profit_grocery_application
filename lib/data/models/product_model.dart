import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required String id,
    required String name,
    required String image,
    String? description,
    required double price,
    double? mrp,
    bool inStock = true,
    required String categoryId,
    String? subcategoryId,
    List<String> tags = const [],
    bool isFeatured = false,
    bool isActive = true,
  }) : super(
          id: id,
          name: name,
          image: image,
          description: description,
          price: price,
          mrp: mrp,
          inStock: inStock,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          tags: tags,
          isFeatured: isFeatured,
          isActive: isActive,
        );

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
      subcategoryId: json['subcategoryId'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
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
      'subcategoryId': subcategoryId,
      'tags': tags,
      'isFeatured': isFeatured,
      'isActive': isActive,
    };
  }

  // Create a copy of the product with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    double? price,
    double? mrp,
    bool? inStock,
    String? categoryId,
    String? subcategoryId,
    List<String>? tags,
    bool? isFeatured,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      inStock: inStock ?? this.inStock,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
    );
  }
}