import 'package:flutter/material.dart';

/// Utility for mapping category IDs to colors
/// This centralizes color management across the app
class ColorMapper {
  /// Get a color for a category ID
  static Color getColorForCategory(String? categoryId) {
    if (categoryId == null) return defaultColor;
    
    // Category colors map
    final colorMap = {
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
    
    // Check direct match first
    if (colorMap.containsKey(categoryId)) {
      return colorMap[categoryId]!;
    }
    
    // If no direct match, check for prefix match (e.g., "fruits_" matches "fruits")
    for (final entry in colorMap.entries) {
      if (categoryId.startsWith('${entry.key}_')) {
        return entry.value;
      }
    }
    
    // Try to extract category from the ID if it contains underscores
    if (categoryId.contains('_')) {
      final parts = categoryId.split('_');
      if (parts.length >= 2) {
        // Try first two parts together (e.g., "vegetables_fruits")
        final twoPartKey = "${parts[0]}_${parts[1]}";
        if (colorMap.containsKey(twoPartKey)) {
          return colorMap[twoPartKey]!;
        }
        
        // Then try just the first part
        if (colorMap.containsKey(parts[0])) {
          return colorMap[parts[0]]!;
        }
      }
    }
    
    // Return default color if no match found
    return defaultColor;
  }
  
  /// Default color for unmatched categories
  static const Color defaultColor = Color(0xFF3F4E4F);
}