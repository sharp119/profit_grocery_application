import 'package:flutter/material.dart';

/// This file contains the list of bestseller product IDs
/// These are used for displaying bestseller products on the home page
/// and other relevant sections of the app

class BestsellerProducts {
  /// List of bestseller product IDs
  /// Only product IDs are stored to keep the implementation efficient
  static final List<String> productIds = [
    'vegetables_fruits_1',  // Mixed Vegetables Pack
    'atta_rice_dal_2',      // Basmati Rice 5kg
    'sweets_chocolates_5',  // Chocolate Gift Box 200g
    'tea_coffee_milk_7',    // Herbal Tea 20 Bags
  ];
  
  /// Map of subcategory IDs to their background colors
  /// This ensures consistent coloring across the app
  static final Map<String, Color> subcategoryColors = {
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
}