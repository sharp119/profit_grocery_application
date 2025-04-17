import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:profit_grocery_application/data/models/category_group_model.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();
  
  // Collection references
  CollectionReference get categoriesCollection => _firestore.collection('categories');
  CollectionReference get productsCollection => _firestore.collection('products');
  
  /// Adds a category group to Firestore
  Future<void> addCategoryGroup(CategoryGroup group) async {
    try {
      // Add the category group document
      await categoriesCollection.doc(group.id).set({
        'id': group.id,
        'title': group.title,
        'backgroundColor': group.backgroundColor.value,
        'itemBackgroundColor': group.itemBackgroundColor.value,
      });
      
      // Add each category item as a subcollection document
      for (final item in group.items) {
        await categoriesCollection
            .doc(group.id)
            .collection('items')
            .doc(item.id)
            .set({
          'id': item.id,
          'label': item.label,
          'imagePath': item.imagePath,
          'description': item.description,
        });
      }
    } catch (e) {
      debugPrint('Error adding category group: $e');
      rethrow;
    }
  }
  
  /// Updates a category item image path in Firestore
  Future<void> updateCategoryItemImagePath({
    required String categoryGroupId,
    required String categoryItemId,
    required String imagePath,
  }) async {
    try {
      await categoriesCollection
          .doc(categoryGroupId)
          .collection('items')
          .doc(categoryItemId)
          .update({
        'imagePath': imagePath,
      });
    } catch (e) {
      debugPrint('Error updating category item image path: $e');
      rethrow;
    }
  }
  
  /// Adds a product to Firestore
  Future<String> addProduct(ProductModel product) async {
    try {
      // If subcategoryId is not provided, use a default value
      String subcategoryId = product.subcategoryId ?? 'unknown';
      
      // Determine document reference path - place product under the proper subcategory collection
      // Format: /products/{categoryId}/{subcategoryId}/products/{productId}
      final CollectionReference productsSubcollection = productsCollection
          .doc(product.categoryId)
          .collection(subcategoryId)
          .doc('products')
          .collection('items');
      
      // Use the productId if provided, otherwise auto-generate one
      final DocumentReference docRef = product.id.isNotEmpty
          ? productsSubcollection.doc(product.id)
          : productsSubcollection.doc();
      
      // Get the auto-generated ID if one wasn't provided
      final String productId = product.id.isNotEmpty ? product.id : docRef.id;
      
      // Create a copy of the product with the ID if it wasn't provided
      final ProductModel productWithId = product.id.isNotEmpty
          ? product
          : product.copyWith(id: productId, weight: '', rating: 0.0, brand: '', reviewCount: 0);
      
      // Add the product document under the subcategory
      await docRef.set(productWithId.toJson());
      
      // Also add to main products collection for easier querying across all products
      await productsCollection.doc(productId).set(productWithId.toJson());
      
      return productId;
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }
  
  /// Checks if a category group exists in Firestore
  Future<bool> categoryGroupExists(String categoryGroupId) async {
    try {
      final docSnapshot = await categoriesCollection.doc(categoryGroupId).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if category group exists: $e');
      return false;
    }
  }
  
  /// Gets all category groups from Firestore
  Future<List<Map<String, dynamic>>> getCategoryGroups() async {
    try {
      final querySnapshot = await categoriesCollection.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting category groups: $e');
      return [];
    }
  }
  
  /// Gets all products from Firestore
  Future<List<ProductModel>> getProducts() async {
    try {
      final querySnapshot = await productsCollection.get();
      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(
                {...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }
  
  /// Gets products by category ID from Firestore
  Future<List<ProductModel>> getProductsByCategoryId(String categoryId) async {
    try {
      final querySnapshot = await productsCollection
          .where('categoryId', isEqualTo: categoryId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(
                {...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting products by category ID: $e');
      return [];
    }
  }
  
  /// Gets products by subcategory ID from Firestore
  Future<List<ProductModel>> getProductsBySubcategoryId(String categoryId, String subcategoryId) async {
    try {
      // Get products from the nested structure under products collection
      // Format: /products/{categoryId}/{subcategoryId}/products/items/{productId}
      final querySnapshot = await productsCollection
          .doc(categoryId)
          .collection(subcategoryId)
          .doc('products')
          .collection('items')
          .get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(
                {...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting products by subcategory ID: $e');
      return [];
    }
  }
}