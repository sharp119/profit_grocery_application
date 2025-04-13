import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A utility class to map product categories to consistent background colors
class ColorMapper {
  // Private constructor to prevent instantiation
  ColorMapper._();
  
  /// Central color mapping for all product categories and subcategories
  static final Map<String, Color> categoryColors = {
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
    'electronics': const Color(0xFF34495E),         // Dark blue for electronics
    
    // Map first parts of product IDs to colors as fallbacks
    'atta': const Color(0xFFD5A021),               // Gold/yellow for atta products
    'rice': const Color(0xFFD5A021),               // Gold/yellow for rice products
    'dal': const Color(0xFFD5A021),                // Gold/yellow for dal products
    'oil': const Color(0xFFFF6B6B),                // Soft red for oil products
    'masala': const Color(0xFFFF6B6B),             // Soft red for masala products
    'fruits': const Color(0xFF1A5D1A),             // Dark green for fruits
    'vegetables': const Color(0xFF1A5D1A),         // Dark green for vegetables
  };
  
  /// Get a background color for a product based on its category or subcategory ID
  /// If no matching color is found, returns a default color
  static Color getColorForCategory(String? categoryId) {
    if (categoryId == null) {
      return AppTheme.secondaryColor;
    }
    
    // First check for exact match
    if (categoryColors.containsKey(categoryId)) {
      return categoryColors[categoryId]!;
    }
    
    // Try to extract the category from product ID format (e.g., "vegetables_fruits_1")
    if (categoryId.contains('_')) {
      final segments = categoryId.split('_');
      if (segments.length >= 2) {
        // Try with first two segments (e.g., "vegetables_fruits")
        final baseCategory = '${segments[0]}_${segments[1]}';
        if (categoryColors.containsKey(baseCategory)) {
          return categoryColors[baseCategory]!;
        }
        
        // If not found, try with just the first segment
        if (categoryColors.containsKey(segments[0])) {
          return categoryColors[segments[0]]!;
        }
      }
    }
    
    // Default fallback color
    return AppTheme.secondaryColor;
  }
  
  /// Get a lighter version of the category color for backgrounds
  static Color getLighterColor(String? categoryId, {double opacity = 0.3}) {
    final baseColor = getColorForCategory(categoryId);
    // Lighten the color by mixing with white
    return Color.alphaBlend(
      baseColor.withOpacity(opacity),
      AppTheme.secondaryColor,
    );
  }
  
  /// Get darker version of the category color for borders or accents
  static Color getDarkerColor(String? categoryId) {
    final baseColor = getColorForCategory(categoryId);
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor.withLightness((hslColor.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}