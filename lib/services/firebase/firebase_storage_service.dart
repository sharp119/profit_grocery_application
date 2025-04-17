import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Singleton pattern
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  /// Uploads an image from assets to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadAssetImage({
    required String assetPath,
    required String storagePath,
    String? fileName,
  }) async {
    try {
      // Load the asset as bytes
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get the file name from the asset path if not provided
      final String baseName = fileName ?? path.basename(assetPath);
      
      // Create a reference to the storage location
      final Reference ref = _storage.ref().child('$storagePath/$baseName');
      
      // Upload the bytes
      final UploadTask uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/${path.extension(baseName).replaceAll('.', '')}'),
      );
      
      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading asset image: $e');
      rethrow;
    }
  }
  
  /// Uploads a random image from assets/products folder to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadRandomProductImage({
    required String productId,
    required String categoryId,
  }) async {
    try {
      // Choose a random product image from 1-10
      final int randomIndex = DateTime.now().millisecondsSinceEpoch % 10 + 1;
      final String assetPath = 'assets/products/$randomIndex.png';
      
      // Create storage path based on category and product ID
      final String storagePath = 'products/$categoryId/$productId';
      
      // Upload the image
      return await uploadAssetImage(
        assetPath: assetPath,
        storagePath: storagePath,
        fileName: 'product_image.png',
      );
    } catch (e) {
      debugPrint('Error uploading random product image: $e');
      rethrow;
    }
  }
  
  /// Uploads a category image from assets to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadCategoryImage({
    required String assetPath,
    required String categoryGroupId,
    required String categoryItemId,
  }) async {
    try {
      // Create storage path based on category group and item ID
      final String storagePath = 'categories/$categoryGroupId/$categoryItemId';
      
      // Upload the image
      return await uploadAssetImage(
        assetPath: assetPath,
        storagePath: storagePath,
        fileName: 'category_image.png',
      );
    } catch (e) {
      debugPrint('Error uploading category image: $e');
      rethrow;
    }
  }
}