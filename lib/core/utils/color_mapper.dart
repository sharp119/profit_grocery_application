// lib/core/utils/color_mapper.dart

import 'package:flutter/material.dart';
import '../../data/inventory/bestseller_products.dart';

/// Utility class for mapping categories and subcategories to colors
class ColorMapper {
  /// Get a background color for a product's subcategory or category
  static Color getColorForCategory(
    String categoryOrSubcategoryId, {
    Map<String, Color>? fallbackColors,
  }) {
    // First try from the provided fallback colors
    if (fallbackColors != null && fallbackColors.containsKey(categoryOrSubcategoryId)) {
      return fallbackColors[categoryOrSubcategoryId]!;
    }

    // Then try from the predefined BestsellerProducts color map
    if (BestsellerProducts.subcategoryColors.containsKey(categoryOrSubcategoryId)) {
      return BestsellerProducts.subcategoryColors[categoryOrSubcategoryId]!;
    }

    // Try to extract the main category if it's a subcategory (e.g., "fruits_vegetables_exotic")
    if (categoryOrSubcategoryId.contains('_')) {
      final parts = categoryOrSubcategoryId.split('_');
      if (parts.length >= 2) {
        final mainCategory = "${parts[0]}_${parts[1]}";

        // Try with the main category
        if (BestsellerProducts.subcategoryColors.containsKey(mainCategory)) {
          return BestsellerProducts.subcategoryColors[mainCategory]!;
        }

        // Try just with the first part
        if (BestsellerProducts.subcategoryColors.containsKey(parts[0])) {
          return BestsellerProducts.subcategoryColors[parts[0]]!;
        }
      }
    }

    // Default colors based on category patterns (Light Pastel Palette)
    if (categoryOrSubcategoryId.contains('vegetable') ||
        categoryOrSubcategoryId.contains('fruit')) {
      return const Color(0xFFC8E6C9); // Light Green for fruits/vegetables
    } else if (categoryOrSubcategoryId.contains('bakery') ||
              categoryOrSubcategoryId.contains('bread')) {
      return const Color(0xFFF5E1DA); // Light Beige for bakery
    } else if (categoryOrSubcategoryId.contains('dairy')) {
      return const Color(0xFFE0F7FA); // Light Cyan for dairy
    } else if (categoryOrSubcategoryId.contains('beauty') ||
              categoryOrSubcategoryId.contains('personal')) {
      return const Color(0xFFF8BBD0); // Light Pink for beauty/personal care
    } else if (categoryOrSubcategoryId.contains('snack') ||
              categoryOrSubcategoryId.contains('chips')) {
      return const Color(0xFFFFF9C4); // Light Yellow for snacks
    }

    // Fallback default color (Light Pastel)
    return const Color(0xFFCFD8DC); // Light Blue Grey as default
  }
}