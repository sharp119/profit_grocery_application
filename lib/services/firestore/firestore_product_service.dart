// lib/services/firestore/firestore_product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logging_service.dart'; // Assuming you have a logging service

class FirestoreProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This method will now return a raw Map<String, dynamic>?
  Future<Map<String, dynamic>?> getProductSectionsById(
      String productId, String categoryId, String subcategoryId) async {
    try {
      final docPath = 'product_detail/$categoryId/items/$subcategoryId/products/$productId';
      LoggingService.logFirestore('FirestoreProductService: Attempting to fetch raw sections from Firestore at path: $docPath');

      final docSnapshot = await _firestore.doc(docPath).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        LoggingService.logFirestore('FirestoreProductService: Successfully fetched raw data for $productId from Firestore.');
        return docSnapshot.data(); // Return the raw map data
      } else {
        LoggingService.logFirestore('FirestoreProductService: Document not found for productId: $productId at path: $docPath');
        return null;
      }
    } catch (e) {
      LoggingService.logError('FirestoreProductService', 'Error getting raw product sections $productId from Firestore: $e');
      return null;
    }
  }
}