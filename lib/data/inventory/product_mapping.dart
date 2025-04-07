import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../core/utils/category_assets.dart';
import '../models/category_group_model.dart';

/// A simple mapping of subcategory IDs to products
class ProductMapping {
  // Map to store products for each subcategory ID
  static final Map<String, List<ProductModel>> products = {};
  
  // Initialize the product mapping
  static void initialize() {
    // Clear any existing mappings
    products.clear();
    
    // Generate products for all category items in all groups
    for (final group in CategoryGroups.all) {
      for (final item in group.items) {
        // Generate 10-15 products for this category item
        final productCount = 10 + (item.id.hashCode % 6).abs(); // Between 10 and 15
        products[item.id] = _generateProducts(item.id, item.label, productCount);
      }
    }
  }
  
  // Get products for a specific subcategory
  static List<ProductModel> getProducts(String subcategoryId) {
    if (products.isEmpty) {
      initialize();
    }
    return products[subcategoryId] ?? [];
  }
  
  // Get all category items in their original order
  static List<CategoryItem> getAllCategoryItems() {
    final List<CategoryItem> allItems = [];
    for (final group in CategoryGroups.all) {
      allItems.addAll(group.items);
    }
    return allItems;
  }
  
  // Get background color for a subcategory
  static Color? getColorForSubcategory(String subcategoryId) {
    for (final group in CategoryGroups.all) {
      for (final item in group.items) {
        if (item.id == subcategoryId) {
          return group.itemBackgroundColor;
        }
      }
    }
    return null;
  }
  
  // Generate simple products with sequential naming
  static List<ProductModel> _generateProducts(String categoryId, String categoryName, int count) {
    return List.generate(count, (index) {
      final bool isDiscounted = index % 3 == 0;
      final double price = 50.0 + (index * 10);
      final double? mrp = isDiscounted ? price * 1.15 : null;
      
      return ProductModel(
        id: '${categoryId}_product_${index + 1}',
        name: 'product_${index + 1}',
        image: CategoryAssets.getRandomProductImage(),
        description: 'Product ${index + 1} from ${categoryName}',
        price: price,
        mrp: mrp,
        categoryId: categoryId,
        subcategoryId: categoryId,
        inStock: index % 5 != 0, // 80% of products are in stock
      );
    });
  }
}