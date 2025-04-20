import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:profit_grocery_application/data/models/category_group_model.dart';
import 'package:profit_grocery_application/data/inventory/product_mapping.dart';

/// This utility class syncs test data to Firestore for development and testing
class FirestoreTestDataSync {
  final FirebaseFirestore _firestore;

  FirestoreTestDataSync({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sync the Bakeries & Biscuits category to Firestore
  Future<void> syncBakeriesBiscuitsCategory() async {
    try {
      // First sync the main category
      await _syncMainCategory();

      // Then sync the subcategories
      await _syncSubcategories();

      // Finally sync the products
      await _syncProducts();

      print('Bakeries & Biscuits category successfully synced to Firestore');
    } catch (e) {
      print('Error syncing Bakeries & Biscuits category: $e');
      rethrow;
    }
  }

  /// Sync the main category
  Future<void> _syncMainCategory() async {
    final bakeriesGroupModel = CategoryGroups.bakeriesAndBiscuits;
    
    await _firestore.collection('categories').doc('bakeries_biscuits').set({
      'id': 'bakeries_biscuits',
      'title': bakeriesGroupModel.title,
      'backgroundColor': bakeriesGroupModel.backgroundColor.value,
      'itemBackgroundColor': bakeriesGroupModel.itemBackgroundColor.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sync the subcategories
  Future<void> _syncSubcategories() async {
    final bakeriesGroupModel = CategoryGroups.bakeriesAndBiscuits;
    final subcategoriesRef = _firestore
        .collection('categories')
        .doc('bakeries_biscuits')
        .collection('items');

    // Create a batch for more efficient writes
    final batch = _firestore.batch();

    // Add each item to the batch
    for (final item in bakeriesGroupModel.items) {
      final docRef = subcategoriesRef.doc(item.id);
      batch.set(docRef, {
        'id': item.id,
        'label': item.label,
        'imagePath': item.imagePath,
        'description': item.description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit the batch
    await batch.commit();
  }

  /// Sync products for all subcategories
  Future<void> _syncProducts() async {
    final productsRef = _firestore.collection('products');
    ProductMapping.initialize();

    // Create a batch for more efficient writes
    final batch = _firestore.batch();

    // For each subcategory, generate and sync products
    for (final item in CategoryGroups.bakeriesAndBiscuits.items) {
      final products = ProductMapping.getProducts(item.id);
      
      for (final product in products) {
        final productId = product.id;
        final docRef = productsRef.doc(productId);
        
        batch.set(docRef, {
          'id': productId,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'mrp': product.mrp,
          'image': product.image,
          'inStock': product.inStock,
          'categoryId': 'bakeries_biscuits',
          'subcategoryId': item.id,
          'tags': product.tags,
          'weight': product.weight,
          'brand': product.brand,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Commit the batch
    await batch.commit();
  }
  
  /// Clean up all test data from Firestore
  Future<void> cleanupTestData() async {
    try {
      // Delete products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: 'bakeries_biscuits')
          .get();
      
      for (final doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete subcategories
      final subcategoriesSnapshot = await _firestore
          .collection('categories')
          .doc('bakeries_biscuits')
          .collection('items')
          .get();
      
      for (final doc in subcategoriesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete main category
      await _firestore.collection('categories').doc('bakeries_biscuits').delete();
      
      print('Test data cleanup completed successfully');
    } catch (e) {
      print('Error cleaning up test data: $e');
      rethrow;
    }
  }
}