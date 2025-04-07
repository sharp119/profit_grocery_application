import 'dart:math';
import 'package:flutter/material.dart';

import '../models/category_group_model.dart';
import '../models/product_model.dart';
import '../../core/utils/category_assets.dart';

/// Utility class for mapping subcategories to products
class ProductSubcategoryMapping {
  static final Random _random = Random();
  
  /// Generate a mapping of subcategory IDs to product lists for a specific category group
  static Map<String, List<ProductModel>> generateProductsForCategoryGroup(CategoryGroup categoryGroup) {
    final Map<String, List<ProductModel>> mapping = {};
    
    // For each subcategory in the category group
    for (final subcategory in categoryGroup.items) {
      // Generate between 10 and 15 products for each subcategory
      final productCount = 10 + _random.nextInt(6); // 10 to 15 products
      
      final products = List.generate(productCount, (index) {
        // Product ID follows the pattern: subcategoryId_product_index
        final productId = '${subcategory.id}_product_${index + 1}';
        
        // Determine if the product is discounted (about 30% of products are discounted)
        final bool isDiscounted = _random.nextInt(10) < 3;
        
        // Base price between 50 and 500
        final double basePrice = 50.0 + (_random.nextInt(45) * 10);
        
        // Calculate discount if applicable
        final num discountPercentage = isDiscounted ? (5 + _random.nextInt(20)) : 0; // 5% to 25% discount
        final double discountedPrice = isDiscounted 
            ? basePrice * (1 - discountPercentage / 100)
            : basePrice;
        
        // Create the product model
        return ProductModel(
          id: productId,
          name: 'product_${index + 1}', // Simple sequential naming as requested
          description: 'This is product ${index + 1} in the ${subcategory.label} subcategory',
          price: discountedPrice.roundToDouble(),
          mrp: isDiscounted ? basePrice.roundToDouble() : null,
          categoryId: categoryGroup.id, // Parent category ID
          subcategoryId: subcategory.id, // Subcategory ID for color mapping
          image: CategoryAssets.getRandomProductImage(),
          inStock: _random.nextInt(10) < 8, // 80% of products are in stock
          tags: [subcategory.id], // Add subcategory ID as tag for filtering
        );
      });
      
      // Add the products to the mapping
      mapping[subcategory.id] = products;
    }
    
    return mapping;
  }
  
  /// Get a mapping of subcategory IDs to their background colors
  static Map<String, Color> getSubcategoryColors(CategoryGroup categoryGroup) {
    final Map<String, Color> colorMap = {};
    
    for (final subcategory in categoryGroup.items) {
      colorMap[subcategory.id] = categoryGroup.itemBackgroundColor;
    }
    
    return colorMap;
  }
}
