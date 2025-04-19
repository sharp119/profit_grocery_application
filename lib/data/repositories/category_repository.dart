import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore/category_group_firestore_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CategoryGroupFirestore>> fetchCategories() async {
    try {
      // Fetch all category groups
      final categorySnapshot = await _firestore.collection('categories').get();
      
      List<CategoryGroupFirestore> categoryGroups = [];
      
      // For each category group, fetch its items
      for (var doc in categorySnapshot.docs) {
        // Fetch items subcollection for this category
        final itemsSnapshot = await doc.reference.collection('items').get();
        
        // Convert items documents to CategoryItemFirestore objects
        final items = itemsSnapshot.docs
            .map((itemDoc) => CategoryItemFirestore.fromFirestore(itemDoc))
            .toList();
        
        // Create CategoryGroupFirestore with its items
        final categoryGroup = CategoryGroupFirestore.fromFirestore(doc, items);
        categoryGroups.add(categoryGroup);
      }
      
      return categoryGroups;
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }
} 