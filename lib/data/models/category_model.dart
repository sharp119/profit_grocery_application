import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required String id,
    required String name,
    required String image,
    String? description,
    required String type,
    String? tag,
    bool isActive = true,
    int displayOrder = 0,
    List<String> subcategoryIds = const [],
  }) : super(
          id: id,
          name: name,
          image: image,
          description: description,
          type: type,
          tag: tag,
          isActive: isActive,
          displayOrder: displayOrder,
          subcategoryIds: subcategoryIds,
        );

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
    };
  }

  // Create a copy of the category with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    String? type,
    String? tag,
    bool? isActive,
    int? displayOrder,
    List<String>? subcategoryIds,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      type: type ?? this.type,
      tag: tag ?? this.tag,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
    );
  }
}

class SubcategoryModel extends Subcategory {
  const SubcategoryModel({
    required String id,
    required String name,
    required String image,
    required String categoryId,
    bool isActive = true,
    int displayOrder = 0,
  }) : super(
          id: id,
          name: name,
          image: image,
          categoryId: categoryId,
          isActive: isActive,
          displayOrder: displayOrder,
        );

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

  // Create a copy of the subcategory with updated fields
  SubcategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? categoryId,
    bool? isActive,
    int? displayOrder,
  }) {
    return SubcategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}