import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'product_inventory.dart';
import 'bestseller_products.dart';

/// Handles logic for finding similar products to a given product
class SimilarProducts {
  /// Get similar products for a given product ID
  /// 
  /// This function finds products from the same category or subcategory
  /// as the source product.
  /// 
  /// [productId] - The ID of the product to find similar items for
  /// [limit] - Maximum number of similar products to return (default 3)
  /// [excludeSelf] - Whether to exclude the source product from results (default true)
  static List<String> getSimilarProductIds(
    String productId, {
    int limit = 3,
    bool excludeSelf = true,
  }) {
    // Get all products
    final allProducts = ProductInventory.getAllProducts();
    
    // Find the source product
    final sourceProduct = allProducts.firstWhere(
      (product) => product.id == productId,
      orElse: () => allProducts.first, // Default to first product if not found
    );
    
    // Get the category and subcategory IDs
    final categoryId = sourceProduct.categoryId;
    final subcategoryId = sourceProduct.subcategoryId;
    
    // Filter products by matching category or subcategory
    final matchingProducts = allProducts.where((product) {
      // Skip the source product if excludeSelf is true
      if (excludeSelf && product.id == productId) {
        return false;
      }
      
      // Consider products from the same subcategory first
      if (subcategoryId != null && 
          product.subcategoryId != null && 
          product.subcategoryId == subcategoryId) {
        return true;
      }
      
      // Then consider products from the same main category
      return product.categoryId == categoryId;
    }).toList();
    
    // Randomize the matching products to get different recommendations each time
    matchingProducts.shuffle();
    
    // Return limited number of product IDs
    return matchingProducts
        .take(limit)
        .map((product) => product.id)
        .toList();
  }

  /// Get a background color for a product's subcategory
  /// This ensures consistent coloring across the app
  static Color getColorForProduct(ProductModel product) {
    // First, try to get color from the subcategory
    if (product.subcategoryId != null && 
        BestsellerProducts.subcategoryColors.containsKey(product.subcategoryId)) {
      return BestsellerProducts.subcategoryColors[product.subcategoryId]!;
    }
    
    // If no match, try using the category ID
    if (BestsellerProducts.subcategoryColors.containsKey(product.categoryId)) {
      return BestsellerProducts.subcategoryColors[product.categoryId]!;
    }
    
    // If not found, extract the category from the product ID
    if (product.id.contains('_')) {
      final parts = product.id.split('_');
      if (parts.length >= 2) {
        // Try the first two parts together (e.g., "vegetables_fruits")
        final subcategory = "${parts[0]}_${parts[1]}";
        if (BestsellerProducts.subcategoryColors.containsKey(subcategory)) {
          return BestsellerProducts.subcategoryColors[subcategory]!;
        }
        
        // If that fails, just try the first part
        final category = parts[0];
        if (BestsellerProducts.subcategoryColors.containsKey(category)) {
          return BestsellerProducts.subcategoryColors[category]!;
        }
      }
    }
    
    // Default color if no mapping found
    return const Color(0xFF3F4E4F);
  }
}
