import 'package:flutter/material.dart';
import '../category_model.dart';

/// Extended CategoryModel with additional Firestore-specific properties
class FirestoreCategoryModel extends CategoryModel {
  final Color? backgroundColor;
  final Color? itemBackgroundColor;
  final String? parentId; // For subcategories to reference their parent

  const FirestoreCategoryModel({
    required String id,
    required String name,
    required String image,
    String? description,
    required String type,
    String? tag,
    bool isActive = true,
    int displayOrder = 0,
    List<String> subcategoryIds = const [],
    this.backgroundColor,
    this.itemBackgroundColor,
    this.parentId,
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

  // Override copyWith to include new properties
  @override
  FirestoreCategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    String? type,
    String? tag,
    bool? isActive,
    int? displayOrder,
    List<String>? subcategoryIds,
    Color? backgroundColor,
    Color? itemBackgroundColor,
    String? parentId,
  }) {
    return FirestoreCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      type: type ?? this.type,
      tag: tag ?? this.tag,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      parentId: parentId ?? this.parentId,
    );
  }

  // Convert CategoryModel to FirestoreCategoryModel
  static FirestoreCategoryModel fromCategoryModel(
    CategoryModel model, {
    Color? backgroundColor,
    Color? itemBackgroundColor,
    String? parentId,
  }) {
    return FirestoreCategoryModel(
      id: model.id,
      name: model.name,
      image: model.image,
      description: model.description,
      type: model.type,
      tag: model.tag,
      isActive: model.isActive,
      displayOrder: model.displayOrder,
      subcategoryIds: model.subcategoryIds,
      backgroundColor: backgroundColor,
      itemBackgroundColor: itemBackgroundColor,
      parentId: parentId,
    );
  }
}