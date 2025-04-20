import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:profit_grocery_application/domain/entities/category.dart';
import 'package:profit_grocery_application/domain/entities/product.dart';
import 'package:profit_grocery_application/data/models/category_model.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/data/models/firestore/firestore_category_model.dart';

/// Service for loading categories and products from Firestore
class FirestoreProductService {
  final FirebaseFirestore _firestore;

  FirestoreProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all main category groups
  Future<List<FirestoreCategoryModel>> getMainCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FirestoreCategoryModel(
          id: doc.id,
          name: data['title'] ?? '',
          image: data['imagePath'] ?? '',
          type: 'category',
          backgroundColor: _parseColor(data['backgroundColor']),
          itemBackgroundColor: _parseColor(data['itemBackgroundColor']),
        );
      }).toList();
    } catch (e) {
      print('Error getting main categories: $e');
      return [];
    }
  }

  /// Get subcategories for a specific category
  Future<List<FirestoreCategoryModel>> getSubcategories(String categoryId) async {
    try {
      // Based on the screenshots, each category item is directly in the 'items' collection
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('items')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FirestoreCategoryModel(
          id: doc.id,
          name: data['label'] ?? '',
          image: data['imagePath'] ?? '',
          type: 'subcategory',
          parentId: categoryId,
          // We'll use the first Firebase screenshot for reference (bakery_snacks)
          backgroundColor: const Color(0xFFFFECB3), // Light amber for bakeries & biscuits
          itemBackgroundColor: const Color(0xFFFFECB3),
        );
      }).toList();
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  /// Get products for a specific subcategory
  Future<List<ProductModel>> getProductsBySubcategory(String categoryId, String subcategoryId) async {
    try {
      // Based on the screenshots, we need to query the products with categoryGroup and categoryItem
      final snapshot = await _firestore
          .collection('products')
          .where('categoryGroup', isEqualTo: categoryId)
          .where('categoryItem', isEqualTo: subcategoryId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel(
          id: doc.id,
          name: data['name'] ?? '',
          image: data['imagePath'] ?? '', // Note the field is imagePath not image
          description: data['description'],
          price: (data['price'] ?? 0).toDouble(),
          mrp: data['mrp'] != null ? data['mrp'].toDouble() : null,
          inStock: data['inStock'] ?? true,
          categoryId: data['categoryGroup'] ?? '',
          subcategoryId: data['categoryItem'],
          tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
          isFeatured: data['isFeatured'] ?? false,
          isActive: data['isActive'] ?? true,
          weight: data['weight'],
          brand: data['brand'],
        );
      }).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  /// Get all subcategories for bakeries_biscuits category with products
  Future<Map<String, List<ProductModel>>> getBakeriesBiscuitsSubcategoriesWithProducts() async {
    try {
      const String categoryId = 'bakeries_biscuits';
      
      // Get all subcategories for bakeries_biscuits
      final subcategories = await getSubcategories(categoryId);
      
      // Create a map to store products for each subcategory
      final Map<String, List<ProductModel>> categoryProducts = {};
      
      // Load products for each subcategory
      for (final subcategory in subcategories) {
        final products = await getProductsBySubcategory(categoryId, subcategory.id);
        categoryProducts[subcategory.id] = products;
      }
      
      return categoryProducts;
    } catch (e) {
      print('Error getting bakeries_biscuits subcategories with products: $e');
      return {};
    }
  }
  
  /// Convert FirestoreCategoryModel to CategoryModel
  CategoryModel convertToStandardModel(FirestoreCategoryModel model) {
    return CategoryModel(
      id: model.id,
      name: model.name,
      image: model.image,
      description: model.description,
      type: model.type,
      tag: model.tag,
      isActive: model.isActive,
      displayOrder: model.displayOrder,
      subcategoryIds: model.subcategoryIds,
    );
  }
  
  /// Convert a list of FirestoreCategoryModel to a list of CategoryModel
  List<CategoryModel> convertToStandardModels(List<FirestoreCategoryModel> models) {
    return models.map((model) => convertToStandardModel(model)).toList();
  }

  /// Get a specific product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = doc.data()!;
      return ProductModel(
        id: doc.id,
        name: data['name'] ?? '',
        image: data['imagePath'] ?? '',
        description: data['description'],
        price: (data['price'] ?? 0).toDouble(),
        mrp: data['mrp'] != null ? data['mrp'].toDouble() : null,
        inStock: data['inStock'] ?? true,
        categoryId: data['categoryGroup'] ?? '',
        subcategoryId: data['categoryItem'],
        tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
        isFeatured: data['isFeatured'] ?? false,
        isActive: data['isActive'] ?? true,
        weight: data['weight'],
        brand: data['brand'],
      );
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }
  
  /// Helper method to parse color from Firestore
  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) {
      return Colors.transparent;
    }

    if (colorValue is int) {
      return Color(colorValue);
    }

    if (colorValue is String) {
      // Check if the string is a valid hex color
      if (colorValue.startsWith('#')) {
        return Color(int.parse('0xFF${colorValue.substring(1)}'));
      }
    }

    return Colors.transparent;
  }
}