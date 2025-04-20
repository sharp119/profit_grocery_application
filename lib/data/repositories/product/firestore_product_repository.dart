import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';

class FirestoreProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Helper method to ensure we get a properly formatted image URL
  Future<String> _getImageUrl(String? imagePath, String productId) async {
    // If there's no path, just return empty string
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Promote to non-nullable local variable
    final nonNullPath = imagePath;

    // If the image path is already a full Firebase Storage URL
    if (nonNullPath.startsWith('https://firebasestorage.googleapis.com')) {
      // Already has a token, return as is
      if (nonNullPath.contains('token=')) {
        return nonNullPath;
      }

      // Has alt=media but no token: try to refresh the URL
      if (nonNullPath.contains('alt=media') && !nonNullPath.contains('token=')) {
        try {
          final uri = Uri.parse(nonNullPath);
          final segments = uri.pathSegments;
          if (segments.contains('o') && segments.length > segments.indexOf('o') + 1) {
            final objectPath = Uri.decodeFull(segments[segments.indexOf('o') + 1]);
            final ref = _storage.ref().child(objectPath);
            return await ref.getDownloadURL();
          }
        } catch (e) {
          print('Error getting fresh download URL for $productId: $e');
          // fall through and return the original
        }
      }

      return nonNullPath;
    }

    // Otherwise treat it as a storage path
    try {
      var storagePath = nonNullPath;
      if (storagePath.startsWith('/')) {
        storagePath = storagePath.substring(1);
      }
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting download URL for product $productId: $e');
      // Always return a non-null string
      return nonNullPath;
    }
  }

  /// Fetches products for a specific category from Firestore
  Future<List<ProductModel>> fetchProductsByCategory({
    required String categoryGroup,
    required String categoryItem,
  }) async {
    try {
      print('Fetching products for $categoryGroup > $categoryItem');

      final productsSnapshot = await _firestore
          .collection('products')
          .doc(categoryGroup)
          .collection('items')
          .doc(categoryItem)
          .collection('products')
          .get();

      print('Found ${productsSnapshot.docs.length} products');

      final List<ProductModel> products = [];

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final imagePath = data['imagePath'] ??
            data['image'] ??
            data['imageUrl'] ??
            data['photo'] ??
            data['downloadURL'] ??
            '';
        print('PRODUCT IMAGE DEBUG [${doc.id}]: Image path found = $imagePath');
        print('PRODUCT IMAGE DEBUG [${doc.id}]: Document data keys: ${data.keys.toList()}');

        final imageUrl = await _getImageUrl(imagePath, doc.id);
        print('PRODUCT IMAGE DEBUG [${doc.id}]: Final imageUrl = $imageUrl');

        products.add(ProductModel(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] as num?)?.toDouble() ?? 0.0,
          mrp: (data['mrp'] is int)
              ? (data['mrp'] as int).toDouble()
              : (data['mrp'] as num?)?.toDouble() ?? 0.0,
          image: imageUrl,
          inStock: data['inStock'] ?? true,
          categoryId: data['categoryItem'] ?? categoryItem,
          categoryName: categoryGroup,
          brand: data['brand'] as String?,
          weight: data['weight'] as String?,
          rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
          reviewCount: data['reviewCount'] as int?,
        ));
      }

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  /// Fetches all products from all categories
  Future<List<ProductModel>> fetchAllProducts() async {
    try {
      List<ProductModel> allProducts = [];

      final categoryGroupsSnapshot = await _firestore.collection('products').get();

      for (var groupDoc in categoryGroupsSnapshot.docs) {
        final categoryGroup = groupDoc.id;
        final categoryItemsSnapshot = await _firestore
            .collection('products')
            .doc(categoryGroup)
            .collection('items')
            .get();

        for (var itemDoc in categoryItemsSnapshot.docs) {
          final categoryItem = itemDoc.id;
          final productsSnapshot = await _firestore
              .collection('products')
              .doc(categoryGroup)
              .collection('items')
              .doc(categoryItem)
              .collection('products')
              .get();

          for (var doc in productsSnapshot.docs) {
            final data = doc.data();
            final imagePath = data['imagePath'] ??
                data['image'] ??
                data['imageUrl'] ??
                data['photo'] ??
                data['downloadURL'] ??
                '';
            print('ALL PRODUCTS DEBUG [${doc.id}]: Image path found = $imagePath');

            final imageUrl = await _getImageUrl(imagePath, doc.id);
            print('ALL PRODUCTS DEBUG [${doc.id}]: Final imageUrl = $imageUrl');

            allProducts.add(ProductModel(
              id: doc.id,
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              price: (data['price'] is int)
                  ? (data['price'] as int).toDouble()
                  : (data['price'] as num?)?.toDouble() ?? 0.0,
              mrp: (data['mrp'] is int)
                  ? (data['mrp'] as int).toDouble()
                  : (data['mrp'] as num?)?.toDouble() ?? 0.0,
              image: imageUrl,
              inStock: data['inStock'] ?? true,
              categoryId: categoryItem,
              categoryName: categoryGroup,
              brand: data['brand'] as String?,
              weight: data['weight'] as String?,
              rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
              reviewCount: data['reviewCount'] as int?,
            ));
          }
        }
      }

      return allProducts;
    } catch (e) {
      print('Error fetching all products: $e');
      rethrow;
    }
  }
}
