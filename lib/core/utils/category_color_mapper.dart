import 'package:flutter/material.dart';

/// Utility class to map category IDs to their background colors
/// This ensures consistent coloring across all product displays
class CategoryColorMapper {
  // Singleton pattern
  static final CategoryColorMapper _instance = CategoryColorMapper._internal();
  factory CategoryColorMapper() => _instance;
  CategoryColorMapper._internal();

  // Store category colors in a map for quick access
  final Map<String, Color> _categoryColors = {};
  
  // Predefined colors for categories
  final List<Color> _colorPalette = [
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF26A69A), // Teal
    const Color(0xFFEF5350), // Red
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFB74D), // Orange
    const Color(0xFF9575CD), // Deep Purple
    const Color(0xFF4DD0E1), // Cyan
    const Color(0xFFF06292), // Pink
    const Color(0xFF7E57C2), // Purple
    const Color(0xFFD4E157), // Lime
    const Color(0xFF78909C), // Blue Grey
    const Color(0xFFFFD54F), // Amber
    const Color(0xFF4DB6AC), // Teal 300
    const Color(0xFFFF8A65), // Deep Orange
    const Color(0xFF9CCC65), // Light Green
  ];
  
  /// Get a color for a category ID
  /// If the category doesn't have a color yet, assign one from the palette
  Color getColorForCategory(String categoryId) {
    if (!_categoryColors.containsKey(categoryId)) {
      // Assign a color from the palette based on the hash of the category ID
      final colorIndex = categoryId.hashCode.abs() % _colorPalette.length;
      _categoryColors[categoryId] = _colorPalette[colorIndex];
    }
    
    return _categoryColors[categoryId]!;
  }
  
  /// Pre-assign colors to a list of category IDs
  void preAssignColors(List<String> categoryIds) {
    for (final categoryId in categoryIds) {
      getColorForCategory(categoryId);
    }
  }
  
  /// Get current color mapping (for debugging)
  Map<String, Color> get currentMapping => Map.unmodifiable(_categoryColors);
  
  /// Clear all assigned colors (for testing)
  void clear() {
    _categoryColors.clear();
  }
}
