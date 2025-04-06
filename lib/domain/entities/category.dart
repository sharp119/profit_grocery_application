import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String image;
  final String? description;
  final String type; // 'regular', 'store', 'promotional'
  final String? tag; // For promotional categories: 'Featured', 'New Launch', etc.
  final bool isActive;
  final int displayOrder;
  final List<String> subcategoryIds;
  final String? icon; // Added field for icon
  final int? productCount; // Added field for product count
  final List<String>? productThumbnails; // Added field for product thumbnails

  const Category({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    required this.type,
    this.tag,
    this.isActive = true,
    this.displayOrder = 0,
    this.subcategoryIds = const [],
    this.icon,
    this.productCount,
    this.productThumbnails,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        description,
        type,
        tag,
        isActive,
        displayOrder,
        subcategoryIds,
        icon,
        productCount,
        productThumbnails,
      ];
}

class Subcategory extends Equatable {
  final String id;
  final String name;
  final String image;
  final String categoryId;
  final bool isActive;
  final int displayOrder;

  const Subcategory({
    required this.id,
    required this.name,
    required this.image,
    required this.categoryId,
    this.isActive = true,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        categoryId,
        isActive,
        displayOrder,
      ];
}