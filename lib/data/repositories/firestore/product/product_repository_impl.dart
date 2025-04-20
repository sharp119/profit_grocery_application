import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';
import '../../../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  ProductRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _storage = storage ?? FirebaseStorage.instance;
  
  @override
  Future<List<Product>> getAllProducts() async {
    try {
      List<Product> allProducts = [];
      
      // Get all categories from products collection
      final categoriesSnapshot = await _firestore.collection('products').get();
      
      // For each category, get all subcategories
      for (final categoryDoc in categoriesSnapshot.docs) {
        final categoryId = categoryDoc.id;
        
        // Get subcategories in this category
        final subcategoriesSnapshot = await _firestore.collection('products')
            .doc(categoryId)
            .collection('items')
            .get();
        
        // For each subcategory, get all products
        for (final subcategoryDoc in subcategoriesSnapshot.docs) {
          final subcategoryId = subcategoryDoc.id;
          
          // Get products in this subcategory
          final productsSnapshot = await _firestore.collection('products')
              .doc(categoryId)
              .collection('items')
              .doc(subcategoryId)
              .collection('products')
              .get();
          
          // Convert to domain entities and add to the list
          final products = productsSnapshot.docs.map((doc) {
            final productModel = ProductModel.fromFirestore(doc);
            return productModel.toEntity();
          }).toList();
          
          allProducts.addAll(products);
        }
      }
      
      return allProducts;
    } catch (e) {
      debugPrint('Error getting all products: $e');
      rethrow;
    }
  }
  
  @override
  Future<Product?> getProductById(String productId) async {
    try {
      // We need to search in all categories and subcategories
      // to find the product with this ID
      
      // Get all categories
      final categoriesSnapshot = await _firestore.collection('products').get();
      
      for (final categoryDoc in categoriesSnapshot.docs) {
        final categoryId = categoryDoc.id;
        
        // Get subcategories in this category
        final subcategoriesSnapshot = await _firestore.collection('products')
            .doc(categoryId)
            .collection('items')
            .get();
        
        for (final subcategoryDoc in subcategoriesSnapshot.docs) {
          final subcategoryId = subcategoryDoc.id;
          
          // Try to find the product in this subcategory
          try {
            final productDoc = await _firestore.collection('products')
                .doc(categoryId)
                .collection('items')
                .doc(subcategoryId)
                .collection('products')
                .where(FieldPath.documentId, isEqualTo: productId)
                .limit(1)
                .get();
            
            if (productDoc.docs.isNotEmpty) {
              final productModel = ProductModel.fromFirestore(productDoc.docs.first);
              return productModel.toEntity();
            }
          } catch (e) {
            // Continue searching in other subcategories
            debugPrint('Error searching in $categoryId/$subcategoryId: $e');
          }
        }
      }
      
      // If we get here, the product was not found
      return null;
    } catch (e) {
      debugPrint('Error getting product by ID: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      List<Product> categoryProducts = [];
      
      // Get all subcategories in this category
      final subcategoriesSnapshot = await _firestore.collection('products')
          .doc(categoryId)
          .collection('items')
          .get();
      
      // For each subcategory, get all products
      for (final subcategoryDoc in subcategoriesSnapshot.docs) {
        final subcategoryId = subcategoryDoc.id;
        
        // Get products in this subcategory
        final productsSnapshot = await _firestore.collection('products')
            .doc(categoryId)
            .collection('items')
            .doc(subcategoryId)
            .collection('products')
            .get();
        
        // Convert to domain entities and add to the list
        final products = productsSnapshot.docs.map((doc) {
          final productModel = ProductModel.fromFirestore(doc);
          return productModel.toEntity();
        }).toList();
        
        categoryProducts.addAll(products);
      }
      
      return categoryProducts;
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Product>> getProductsBySubcategory(String categoryId, String subcategoryId) async {
    try {
      // Get products in this subcategory
      final productsSnapshot = await _firestore.collection('products')
          .doc(categoryId)
          .collection('items')
          .doc(subcategoryId)
          .collection('products')
          .get();
      
      // Convert to domain entities
      return productsSnapshot.docs.map((doc) {
        final productModel = ProductModel.fromFirestore(doc);
        return productModel.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Error getting products by subcategory: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Product>> getBestsellerProducts() async {
    try {
      List<Product> bestsellerProducts = [];
      
      // Get all bestsellers from the bestsellers collection
      final bestsellersSnapshot = await _firestore.collection('bestsellers').get();
      
      for (final bestsellerDoc in bestsellersSnapshot.docs) {
        // Get the product reference from the bestseller document
        final data = bestsellerDoc.data();
        final productRef = data['ref'] as String?;
        
        if (productRef != null) {
          // Parse the reference path to get category, subcategory, and product ID
          final pathParts = productRef.split('/');
          if (pathParts.length >= 6) {
            final categoryId = pathParts[1]; // 'fruits_vegetables'
            final subcategoryId = pathParts[3]; // 'exotic_vegetables'
            final productId = pathParts[5]; // 'fjVKtTrytyzem9yK5qVK'
            
            try {
              // Get the product document
              final productDoc = await _firestore.collection('products')
                  .doc(categoryId)
                  .collection('items')
                  .doc(subcategoryId)
                  .collection('products')
                  .doc(productId)
                  .get();
              
              if (productDoc.exists) {
                final productModel = ProductModel.fromFirestore(productDoc);
                bestsellerProducts.add(productModel.toEntity());
              }
            } catch (e) {
              debugPrint('Error getting bestseller product $productRef: $e');
            }
          }
        }
      }
      
      return bestsellerProducts;
    } catch (e) {
      debugPrint('Error getting bestseller products: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Product>> getSimilarProducts(String productId, {int limit = 3}) async {
    try {
      // First, get the product to find its category and subcategory
      final product = await getProductById(productId);
      
      if (product == null) {
        return [];
      }
      
      // Get products from the same subcategory
      List<Product> similarProducts = [];
      
      final productsSnapshot = await _firestore.collection('products')
          .doc(product.categoryId)
          .collection('items')
          .doc(product.subcategoryId)
          .collection('products')
          .where(FieldPath.documentId, isNotEqualTo: productId) // Exclude the original product
          .limit(limit)
          .get();
      
      similarProducts = productsSnapshot.docs.map((doc) {
        final productModel = ProductModel.fromFirestore(doc);
        return productModel.toEntity();
      }).toList();
      
      // If we don't have enough similar products, get some from the same category
      if (similarProducts.length < limit) {
        final remainingCount = limit - similarProducts.length;
        
        // Get all subcategories in this category except the current one
        final subcategoriesSnapshot = await _firestore.collection('products')
            .doc(product.categoryId)
            .collection('items')
            .where(FieldPath.documentId, isNotEqualTo: product.subcategoryId)
            .get();
        
        // Randomly select a subcategory
        if (subcategoriesSnapshot.docs.isNotEmpty) {
          final randomIndex = DateTime.now().millisecondsSinceEpoch % subcategoriesSnapshot.docs.length;
          final randomSubcategoryId = subcategoriesSnapshot.docs[randomIndex].id;
          
          // Get products from this subcategory
          final moreProductsSnapshot = await _firestore.collection('products')
              .doc(product.categoryId)
              .collection('items')
              .doc(randomSubcategoryId)
              .collection('products')
              .limit(remainingCount)
              .get();
          
          final moreProducts = moreProductsSnapshot.docs.map((doc) {
            final productModel = ProductModel.fromFirestore(doc);
            return productModel.toEntity();
          }).toList();
          
          similarProducts.addAll(moreProducts);
        }
      }
      
      return similarProducts;
    } catch (e) {
      debugPrint('Error getting similar products: $e');
      rethrow;
    }
  }
}