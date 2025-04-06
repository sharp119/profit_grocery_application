import 'app_constants.dart';

/// Mapping of category IDs to asset paths
class CategoryAssets {
  // Using constants from AppConstants
  static final String basePath = '${AppConstants.assetsImagesPath}categories/';
  static final String subcategoriesPath = AppConstants.assetsSubcategoriesPath;
  
  // Alternative path if the above doesn't work
  static final String altBasePath = AppConstants.assetsCategoriesPath;

  // Category images mapping
  static final Map<String, String> categoryImages = {
    // Grocery & Kitchen
    'vegetables_fruits': '${basePath}1.png',
    'atta_rice_dal': '${basePath}2.png',
    'oil_ghee_masala': '${basePath}3.png',
    'dairy_bread_eggs': '${basePath}4.png',
    'bakery_biscuits': '${basePath}5.png',
    'dry_fruits_cereals': '${basePath}6.png',
    'meat_fish': '${basePath}7.png',
    'kitchenware': '${basePath}8.png',
    
    // Snacks & Drinks
    'chips_namkeen': '${basePath}9.png',
    'sweets_chocolates': '${basePath}10.png',
    'drinks_juices': '${basePath}11.png',
    'tea_coffee_milk': '${basePath}12.png',
    'instant_food': '${basePath}13.png',
    'sauces_spreads': '${basePath}14.png',
    'paan_corner': '${basePath}15.png',
    'ice_cream': '${basePath}16.png',
    
    // Beauty & Personal Care
    'skin_care': '${basePath}17.png',
    'hair_care': '${basePath}18.png',
    'makeup': '${basePath}19.png',
    'fragrances': '${basePath}20.png',
    
    // Additional categories
    'men_grooming': '${basePath}17.png', // Reusing existing image
    'bath_body': '${basePath}18.png',     // Reusing existing image
    'feminine_hygiene': '${basePath}19.png', // Reusing existing image
    'personal_care': '${basePath}20.png', // Reusing existing image
    
    // Fruits & Vegetables
    'fresh_fruits': '${basePath}1.png',   // Reusing existing image
    'fresh_vegetables': '${basePath}1.png', // Reusing existing image
    'herbs_seasonings': '${basePath}3.png', // Reusing existing image
    'organic': '${basePath}1.png',        // Reusing existing image
    'exotic_fruits': '${basePath}1.png',  // Reusing existing image
    'exotic_vegetables': '${basePath}1.png', // Reusing existing image
    'cut_fruits': '${basePath}1.png',     // Reusing existing image
    'cut_vegetables': '${basePath}1.png', // Reusing existing image
    
    // Dairy, Bread & Eggs
    'milk': '${basePath}4.png',          // Reusing existing image
    'bread': '${basePath}4.png',         // Reusing existing image
    'eggs': '${basePath}4.png',          // Reusing existing image
    'butter_cheese': '${basePath}4.png', // Reusing existing image
    'curd_yogurt': '${basePath}4.png',   // Reusing existing image
    'paneer_tofu': '${basePath}4.png',   // Reusing existing image
    'cream_whitener': '${basePath}4.png', // Reusing existing image
    'condensed_milk': '${basePath}4.png', // Reusing existing image
    
    // Bakery & Biscuits
    'cookies': '${basePath}5.png',       // Reusing existing image
    'rusk_khari': '${basePath}5.png',    // Reusing existing image
    'cakes_pastries': '${basePath}5.png', // Reusing existing image
    'buns_pavs': '${basePath}5.png',     // Reusing existing image
    'premium_cookies': '${basePath}5.png', // Reusing existing image
    'tea_time': '${basePath}5.png',      // Reusing existing image
    'cream_biscuits': '${basePath}5.png', // Reusing existing image
    'bakery_snacks': '${basePath}5.png', // Reusing existing image
    
    // Soft Drinks & Energy Drinks
    'soft_drinks': '${basePath}11.png',  // Reusing existing image
    'energy_drinks': '${basePath}11.png', // Reusing existing image
    
    // Cleaning & Household
    'cleaning_household': '${basePath}8.png', // Reusing existing image
  };

  /// Get the image path for a category ID
  static String getImagePath(String categoryId) {
    // Get path from the map or use a default
    final imagePath = categoryImages[categoryId] ?? '${basePath}1.png';
    return imagePath;
  }
  
  /// Fallback method to get alternative path if the main path fails
  static String getAlternativeImagePath(String categoryId) {
    // Extract just the filename from the original path
    final String originalPath = categoryImages[categoryId] ?? '${basePath}1.png';
    final String fileName = originalPath.split('/').last;
    return '${altBasePath}$fileName';
  }
}