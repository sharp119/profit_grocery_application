import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  // Helper method to safely parse price values
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing price: $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  const ProductModel({
    required String id,
    required String name,
    required String image,
    String? description,
    required double price,
    double? mrp,
    bool inStock = true,
    required String categoryId,
    String? categoryName,
    String? subcategoryId,
    List<String> tags = const [],
    bool isFeatured = false,
    bool isActive = true,
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
  }) : super(
          id: id,
          name: name,
          image: image,
          description: description,
          price: price,
          mrp: mrp,
          inStock: inStock,
          categoryId: categoryId,
          categoryName: categoryName,
          subcategoryId: subcategoryId,
          tags: tags,
          isFeatured: isFeatured,
          isActive: isActive,
          weight: weight,
          brand: brand,
          sellerName: sellerName,
          rating: rating,
          reviewCount: reviewCount,
          nutritionalInfo: nutritionalInfo,
          ingredients: ingredients,
          sku: sku,
          productType: productType,
          quantity: quantity,
          categoryGroup: categoryGroup,
        );

  // Factory constructor to create a ProductModel from Firestore DocumentSnapshot
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Product',
      image: data['imagePath'] ?? data['image'] ?? '',
      description: data['description'],
      price: _parsePrice(data['price']),
      mrp: data['mrp'] != null ? _parsePrice(data['mrp']) : null,
      inStock: data['inStock'] ?? true,
      categoryId: data['categoryId'] ?? data['categoryItem'] ?? '',
      categoryName: data['categoryName'],
      subcategoryId: data['subcategoryId'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      weight: data['weight'],
      brand: data['brand'],
      sellerName: data['sellerName'],
      rating: data['rating'] != null ? _parsePrice(data['rating']) : null,
      reviewCount: data['reviewCount'],
      nutritionalInfo: data['nutritionalInfo'],
      ingredients: data['ingredients'],
      sku: data['sku'],
      productType: data['productType'],
      quantity: data['quantity'] is int ? data['quantity'] : null,
      categoryGroup: data['categoryGroup'],
    );
  }
  
  // Convert to domain entity - helpful when we need to add more logic in the future
  Product toEntity() => this;
  
  // Factory constructor to create a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      description: json['description'],
      price: _parsePrice(json['price']),
      mrp: json['mrp'] != null ? _parsePrice(json['mrp']) : null,
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
      rating: json['rating'] != null ? _parsePrice(json['rating']) : null,
      reviewCount: json['reviewCount'],
      nutritionalInfo: json['nutritionalInfo'],
      ingredients: json['ingredients'],
      sku: json['sku'],
      productType: json['productType'],
      quantity: json['quantity'],
      categoryGroup: json['categoryGroup'],
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
      'nutritionalInfo': nutritionalInfo,
      'ingredients': ingredients,
      'sku': sku,
      'productType': productType,
      'quantity': quantity,
      'categoryGroup': categoryGroup,
    };
  }

  // Create a copy of the product with updated fields
  @override
  ProductModel copyWith({
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
    );
  }
}