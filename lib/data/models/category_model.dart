import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({
    required super.id,
    required super.name,
    required super.image,
    super.description,
    required super.type,
    super.tag,
    super.isActive = true,
    super.displayOrder = 0,
    super.subcategoryIds = const [],
    super.icon,
    super.productCount,
    super.productThumbnails,
  });

  // Factory constructor to create a CategoryModel from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      description: json['description'],
      type: json['type'],
      tag: json['tag'],
      isActive: json['isActive'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
      subcategoryIds: json['subcategoryIds'] != null
          ? List<String>.from(json['subcategoryIds'])
          : [],
      icon: json['icon'],
      productCount: json['productCount'],
      productThumbnails: json['productThumbnails'] != null
          ? List<String>.from(json['productThumbnails'])
          : null,
    );
  }

  // Convert CategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'type': type,
      'tag': tag,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'subcategoryIds': subcategoryIds,
      'icon': icon,
      'productCount': productCount,
      'productThumbnails': productThumbnails,
    };
  }
}

class SubcategoryModel extends Subcategory {
  SubcategoryModel({
    required super.id,
    required super.name,
    required super.image,
    required super.categoryId,
    super.isActive = true,
    super.displayOrder = 0,
  });

  // Factory constructor to create a SubcategoryModel from JSON
  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      categoryId: json['categoryId'],
      isActive: json['isActive'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  // Convert SubcategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'categoryId': categoryId,
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }
}
