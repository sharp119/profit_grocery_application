import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'product_inventory.dart';

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
    // Color map
    final Map<String, Color> subcategoryColors = {
      // Main category colors
      'grocery_kitchen': const Color(0xFF567189),   // Slate blue for grocery
      'fresh_fruits': const Color(0xFF1A5D1A),      // Dark green for fresh fruits
      'vegetables_fruits': const Color(0xFF1A5D1A),  // Dark green for vegetables & fruits
      'cleaning_household': const Color(0xFF4682A9), // Blue for cleaning supplies
      
      // Food subcategories
      'atta_rice_dal': const Color(0xFFD5A021),      // Gold/yellow for grains
      'sweets_chocolates': const Color(0xFFBF3131),  // Dark red for sweets
      'tea_coffee_milk': const Color(0xFF6C3428),    // Coffee brown for tea/coffee
      'oil_ghee_masala': const Color(0xFFFF6B6B),    // Soft red for oils/spices
      'dry_fruits_cereals': const Color(0xFFABC4AA), // Sage green for dry fruits
      'kitchenware': const Color(0xFF3F4E4F),        // Dark slate for kitchenware
      'instant_food': const Color(0xFFEEBB4D),       // Amber for instant food
      'sauces_spreads': const Color(0xFF9A3B3B),     // Burgundy for sauces
      'chips_namkeen': const Color(0xFFECB159),      // Yellow/orange for chips
      'drinks_juices': const Color(0xFF219C90),      // Teal for drinks
      'paan_corner': const Color(0xFF116A7B),        // Teal for paan
      'ice_cream': const Color(0xFFCDDBD5),          // Light mint for ice cream
      
      // Additional categories
      'snacks': const Color(0xFFECB159),             // Yellow/orange for snacks
      'bakery': const Color(0xFFD8B48F),             // Tan for bakery
      'dairy': const Color(0xFFDFECEC),              // Off-white for dairy
      'personal_care': const Color(0xFFD988A1),      // Pink for personal care
      'baby_care': const Color(0xFFAED6F1),          // Light blue for baby care
      'pet_care': const Color(0xFF8D6E63),           // Brown for pet care
      'household': const Color(0xFF7E8C8D),          // Gray for household
      'electronics': const Color(0xFF34495E),        // Dark blue for electronics
      
      // Map first parts of product IDs to colors as fallbacks
      'atta': const Color(0xFFD5A021),               // Gold/yellow for atta products
      'rice': const Color(0xFFD5A021),               // Gold/yellow for rice products
      'dal': const Color(0xFFD5A021),                // Gold/yellow for dal products
      'oil': const Color(0xFFFF6B6B),                // Soft red for oil products
      'masala': const Color(0xFFFF6B6B),             // Soft red for masala products
      'fruits': const Color(0xFF1A5D1A),             // Dark green for fruits
      'vegetables': const Color(0xFF1A5D1A),         // Dark green for vegetables
    };
    
    // First, try to get color from the subcategory
    if (product.subcategoryId != null && 
        subcategoryColors.containsKey(product.subcategoryId)) {
      return subcategoryColors[product.subcategoryId]!;
    }
    
    // If no match, try using the category ID
    if (subcategoryColors.containsKey(product.categoryId)) {
      return subcategoryColors[product.categoryId]!;
    }
    
    // If not found, extract the category from the product ID
    if (product.id.contains('_')) {
      final parts = product.id.split('_');
      if (parts.length >= 2) {
        // Try the first two parts together (e.g., "vegetables_fruits")
        final subcategory = "${parts[0]}_${parts[1]}";
        if (subcategoryColors.containsKey(subcategory)) {
          return subcategoryColors[subcategory]!;
        }
        
        // If that fails, just try the first part
        final category = parts[0];
        if (subcategoryColors.containsKey(category)) {
          return subcategoryColors[category]!;
        }
      }
    }
    
    // Default color if no mapping found
    return const Color(0xFF3F4E4F);
  }
}
