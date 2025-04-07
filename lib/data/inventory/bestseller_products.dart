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
    'vegetables_fruits': const Color(0xFF1A5D1A),  // Dark green for vegetables & fruits
    'atta_rice_dal': const Color(0xFFD5A021),      // Gold/yellow for grains
    'sweets_chocolates': const Color(0xFFBF3131),  // Dark red for sweets
    'tea_coffee_milk': const Color(0xFF6C3428),    // Coffee brown for tea/coffee
    
    // Additional subcategories for similar products
    'oil_ghee_masala': const Color(0xFFFF6B6B),    // Soft red for oils/spices
    'dry_fruits_cereals': const Color(0xFFABC4AA), // Sage green for dry fruits
    'kitchenware': const Color(0xFF3F4E4F),        // Dark slate for kitchenware
    'instant_food': const Color(0xFFEEBB4D),       // Amber for instant food
    'sauces_spreads': const Color(0xFF9A3B3B),     // Burgundy for sauces
    'chips_namkeen': const Color(0xFFECB159),      // Yellow/orange for chips
    'drinks_juices': const Color(0xFF219C90),      // Teal for drinks
    'paan_corner': const Color(0xFF116A7B),        // Teal for paan
    'ice_cream': const Color(0xFFCDDBD5),          // Light mint for ice cream
  };
}