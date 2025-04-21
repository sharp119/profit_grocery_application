import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:profit_grocery_application/data/models/firestore/category_group_firestore_model.dart';
import 'package:profit_grocery_application/domain/entities/category.dart';
import 'package:profit_grocery_application/services/logging_service.dart';

/// A centralized service for category data access
/// This service provides cached category data and handles Firestore queries efficiently
class SharedCategoryService {
  // Singleton pattern
  static final SharedCategoryService _instance = SharedCategoryService._internal();
  
  factory SharedCategoryService() => _instance;
  
  SharedCategoryService._internal() {
    _initializeCache();
  }

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Cache for categories
  final Map<String, CategoryGroupFirestore> _categoryGroupCache = {};
  final Map<String, CategoryItemFirestore> _categoryItemCache = {};
  final Map<String, List<CategoryItemFirestore>> _subcategoriesCache = {};
  List<CategoryGroupFirestore>? _allCategoriesCache;
  
  bool _isCacheInitialized = false;

  // Cache initialization
  Future<void> _initializeCache() async {
    if (_isCacheInitialized) return;
    
    LoggingService.logFirestore('CAT_CACHE: Initializing category cache system');
    print('CAT_CACHE: Initializing category cache system');
    
    // We'll do lazy initialization to avoid unnecessary Firestore reads
    _isCacheInitialized = true;
    
    LoggingService.logFirestore('CAT_CACHE: Cache system initialized with empty caches');
    print('CAT_CACHE: Cache system initialized with empty caches');
    LoggingService.logFirestore('CAT_CACHE: Using memory-based cache (not SharedPreferences)');
    print('CAT_CACHE: Using memory-based cache (not SharedPreferences)');
  }
  
  /// Get all category groups with caching
  Future<List<CategoryGroupFirestore>> getAllCategories() async {
    try {
      // Return from cache if available
      if (_allCategoriesCache != null) {
        LoggingService.logFirestore('CAT_CACHE: Cache HIT for all categories - returning ${_allCategoriesCache!.length} category groups from memory');
        print('CAT_CACHE: Cache HIT for all categories - returning ${_allCategoriesCache!.length} category groups from memory');
        return _allCategoriesCache!;
      }
      
      LoggingService.logFirestore('CAT_CACHE: Cache MISS for all categories - fetching from Firestore');
      print('CAT_CACHE: Cache MISS for all categories - fetching from Firestore');
      
      // Fetch all category groups
      final categorySnapshot = await _firestore.collection('categories').get();
      
      LoggingService.logFirestore('CAT_CACHE: Fetched ${categorySnapshot.docs.length} category groups from Firestore');
      print('CAT_CACHE: Fetched ${categorySnapshot.docs.length} category groups from Firestore');
      
      List<CategoryGroupFirestore> categoryGroups = [];
      
      // For each category group, fetch its items
      for (var doc in categorySnapshot.docs) {
        final categoryId = doc.id;
        LoggingService.logFirestore('CAT_CACHE: Processing category group: $categoryId');
        print('CAT_CACHE: Processing category group: $categoryId');
        
        // Fetch items subcollection for this category
        final itemsSnapshot = await doc.reference.collection('items').get();
        
        LoggingService.logFirestore('CAT_CACHE: Fetched ${itemsSnapshot.docs.length} items for category $categoryId');
        print('CAT_CACHE: Fetched ${itemsSnapshot.docs.length} items for category $categoryId');
        
        // Convert items documents to CategoryItemFirestore objects
        final items = itemsSnapshot.docs
            .map((itemDoc) => CategoryItemFirestore.fromFirestore(itemDoc))
            .toList();
        
        // Create CategoryGroupFirestore with its items
        final categoryGroup = CategoryGroupFirestore.fromFirestore(doc, items);
        
        // Log background colors
        LoggingService.logFirestore('CAT_CACHE: Category $categoryId colors - Background: ${categoryGroup.backgroundColor}, Item Background: ${categoryGroup.itemBackgroundColor}');
        print('CAT_CACHE: Category $categoryId colors - Background: ${categoryGroup.backgroundColor}, Item Background: ${categoryGroup.itemBackgroundColor}');
        
        // Cache this category group and its items
        _categoryGroupCache[categoryGroup.id] = categoryGroup;
        _subcategoriesCache[categoryGroup.id] = items;
        
        LoggingService.logFirestore('CAT_CACHE: Cached category group $categoryId with ${items.length} items');
        print('CAT_CACHE: Cached category group $categoryId with ${items.length} items');
        
        // Cache individual category items
        for (final item in items) {
          _categoryItemCache['${categoryGroup.id}/${item.id}'] = item;
          LoggingService.logFirestore('CAT_CACHE: Cached category item ${item.id} (${item.label}) in category $categoryId');
          // Don't print every item to avoid log spam
        }
        
        categoryGroups.add(categoryGroup);
      }
      
      // Update the all categories cache
      _allCategoriesCache = categoryGroups;
      
      LoggingService.logFirestore('CAT_CACHE: All categories cached - ${categoryGroups.length} category groups with a total of ${_categoryItemCache.length} items');
      print('CAT_CACHE: All categories cached - ${categoryGroups.length} category groups with a total of ${_categoryItemCache.length} items');
      
      return categoryGroups;
    } catch (e) {
      LoggingService.logError('CAT_CACHE', 'Error fetching all categories: $e');
      print('CAT_CACHE ERROR: Failed to fetch categories - $e');
      rethrow;
    }
  }
  
  /// Get a specific category group by ID
  Future<CategoryGroupFirestore?> getCategoryById(String categoryId) async {
    try {
      // Check cache first
      if (_categoryGroupCache.containsKey(categoryId)) {
        LoggingService.logFirestore('SharedCategoryService: Cache hit for category $categoryId');
        return _categoryGroupCache[categoryId];
      }
      
      LoggingService.logFirestore('SharedCategoryService: Cache miss for category $categoryId, fetching from Firestore');
      
      // Fetch the category from Firestore
      final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
      
      if (!categoryDoc.exists) {
        LoggingService.logFirestore('SharedCategoryService: Category $categoryId not found');
        return null;
      }
      
      // Fetch subcategories
      final itemsSnapshot = await categoryDoc.reference.collection('items').get();
      
      // Convert to CategoryItemFirestore objects
      final items = itemsSnapshot.docs
          .map((itemDoc) => CategoryItemFirestore.fromFirestore(itemDoc))
          .toList();
      
      // Create CategoryGroupFirestore
      final categoryGroup = CategoryGroupFirestore.fromFirestore(categoryDoc, items);
      
      // Cache the result
      _categoryGroupCache[categoryId] = categoryGroup;
      _subcategoriesCache[categoryId] = items;
      
      // Cache individual category items
      for (final item in items) {
        _categoryItemCache['${categoryId}/${item.id}'] = item;
      }
      
      return categoryGroup;
    } catch (e) {
      LoggingService.logError('SharedCategoryService', 'Error getting category $categoryId: $e');
      return null;
    }
  }
  
  /// Get subcategories for a category
  Future<List<CategoryItemFirestore>> getSubcategoriesByCategoryId(String categoryId) async {
    try {
      // Check cache first
      if (_subcategoriesCache.containsKey(categoryId)) {
        LoggingService.logFirestore('SharedCategoryService: Cache hit for subcategories of $categoryId');
        return _subcategoriesCache[categoryId]!;
      }
      
      LoggingService.logFirestore('SharedCategoryService: Cache miss for subcategories of $categoryId, fetching from Firestore');
      
      // If we don't have the subcategories in cache, fetch the entire category
      final category = await getCategoryById(categoryId);
      
      if (category == null) {
        LoggingService.logFirestore('SharedCategoryService: Category $categoryId not found');
        return [];
      }
      
      // The subcategories should now be in cache
      return _subcategoriesCache[categoryId] ?? [];
    } catch (e) {
      LoggingService.logError('SharedCategoryService', 'Error getting subcategories for $categoryId: $e');
      return [];
    }
  }
  
  /// Get full path to a category item (subcategory)
  Future<CategoryItemFirestore?> getCategoryItem(String categoryId, String itemId) async {
    try {
      // Check cache first
      final cacheKey = '$categoryId/$itemId';
      if (_categoryItemCache.containsKey(cacheKey)) {
        LoggingService.logFirestore('SharedCategoryService: Cache hit for category item $cacheKey');
        return _categoryItemCache[cacheKey];
      }
      
      LoggingService.logFirestore('SharedCategoryService: Cache miss for category item $cacheKey, fetching from Firestore');
      
      // Fetch the subcategories for this category
      final subcategories = await getSubcategoriesByCategoryId(categoryId);
      
      // Find the specific subcategory
      final categoryItem = subcategories.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Category item $itemId not found in category $categoryId'),
      );
      
      // Cache this item
      _categoryItemCache[cacheKey] = categoryItem;
      
      return categoryItem;
    } catch (e) {
      LoggingService.logError('SharedCategoryService', 'Error getting category item $categoryId/$itemId: $e');
      return null;
    }
  }
  
  /// Get image URL for a category item
  Future<String> getCategoryImageUrl(String categoryId, String itemId) async {
    try {
      final categoryItem = await getCategoryItem(categoryId, itemId);
      
      if (categoryItem == null || categoryItem.imagePath.isEmpty) {
        return '';
      }
      
      // If it's already a URL
      if (categoryItem.imagePath.startsWith('http')) {
        return categoryItem.imagePath;
      }
      
      // Otherwise, get the download URL
      final storagePath = categoryItem.imagePath;
      final storageRef = _storage.ref().child(storagePath);
      return await storageRef.getDownloadURL();
    } catch (e) {
      LoggingService.logError('SharedCategoryService', 'Error getting image URL for $categoryId/$itemId: $e');
      return '';
    }
  }
  
  /// Generate a map of subcategory IDs to background colors
  /// This ensures consistent coloring across the app
  Future<Map<String, Color>> getSubcategoryColors() async {
    final Map<String, Color> colors = {};
    
    try {
      // Get all categories first
      final categories = await getAllCategories();
      
      // Start with some default colors
      const List<Color> defaultColors = [
        Color(0xFF1A5D1A), // Dark green
        Color(0xFFD5A021), // Gold/yellow
        Color(0xFFFF6B6B), // Soft red
        Color(0xFFE5BEEC), // Light lavender
        Color(0xFFA9907E), // Brown
        Color(0xFFABC4AA), // Sage green
        Color(0xFF675D50), // Dark brown
        Color(0xFF3F4E4F), // Dark slate
        Color(0xFFECB159), // Yellow/orange
        Color(0xFFBF3131), // Dark red
        Color(0xFF219C90), // Teal
        Color(0xFF6C3428), // Coffee brown
      ];
      
      // Assign colors to categories and subcategories
      int colorIndex = 0;
      for (final category in categories) {
        // Assign a color to this category group
        colors[category.id] = defaultColors[colorIndex % defaultColors.length];
        colorIndex++;
        
        // Assign colors to subcategories
        for (final subcategory in category.items) {
          // Create a compound key for the subcategory
          final subcategoryKey = '${category.id}/${subcategory.id}';
          
          // Use a variation of the category color
          final baseColor = colors[category.id]!;
          final hslColor = HSLColor.fromColor(baseColor);
          final variantColor = hslColor.withLightness(
            (hslColor.lightness + 0.2).clamp(0.0, 1.0)
          ).toColor();
          
          colors[subcategoryKey] = variantColor;
          
          // Also store with just the subcategory ID for fallback
          if (!colors.containsKey(subcategory.id)) {
            colors[subcategory.id] = variantColor;
          }
        }
      }
    } catch (e) {
      LoggingService.logError('SharedCategoryService', 'Error generating subcategory colors: $e');
    }
    
    return colors;
  }
  
  /// Get all currently cached categories without fetching from Firestore
  /// Returns an empty list if cache is not initialized
  List<CategoryGroupFirestore> getCachedCategories() {
    LoggingService.logFirestore('CAT_CACHE: Getting categories from cache only (no Firestore fetch)');
    print('CAT_CACHE: Getting categories from cache only (no Firestore fetch)');
    
    // If we have all categories cached, return them
    if (_allCategoriesCache != null) {
      LoggingService.logFirestore('CAT_CACHE: Returning ${_allCategoriesCache!.length} categories from all-categories cache');
      print('CAT_CACHE: Returning ${_allCategoriesCache!.length} categories from all-categories cache');
      return _allCategoriesCache!;
    }
    
    // If we don't have all categories cached but have individual categories
    if (_categoryGroupCache.isNotEmpty) {
      final categories = _categoryGroupCache.values.toList();
      LoggingService.logFirestore('CAT_CACHE: Returning ${categories.length} categories from individual category cache');
      print('CAT_CACHE: Returning ${categories.length} categories from individual category cache');
      return categories;
    }
    
    // No categories in cache
    LoggingService.logFirestore('CAT_CACHE: No categories in cache yet');
    print('CAT_CACHE: No categories in cache yet');
    return [];
  }
  
  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'categoryGroups': _categoryGroupCache.length,
      'categoryItems': _categoryItemCache.length,
      'subcategories': _subcategoriesCache.length,
      'allCategoriesInitialized': _allCategoriesCache != null ? 1 : 0,
    };
  }

  /// Clear the category cache
  void clearCache() {
    _categoryGroupCache.clear();
    _categoryItemCache.clear();
    _subcategoriesCache.clear();
    _allCategoriesCache = null;
    LoggingService.logFirestore('CAT_CACHE: Category cache cleared');
    print('CAT_CACHE: Category cache cleared');
  }
}
