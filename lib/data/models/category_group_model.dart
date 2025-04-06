import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_assets.dart';

/// A model representing a group of categories displayed in a 4x2 grid
class CategoryGroup {
  final String id;
  final String title;
  final List<CategoryItem> items;
  final Color backgroundColor;
  final Color itemBackgroundColor; // Single color for all items in the category

  CategoryGroup({
    required this.id,
    required this.title,
    required this.items,
    required this.backgroundColor,
    required this.itemBackgroundColor,
  }) : assert(items.length == 8, 'CategoryGroup must contain exactly 8 items');

  /// Get all image paths from items
  List<String> get images => items.map((item) => item.imagePath).toList();

  /// Get all labels from items
  List<String> get labels => items.map((item) => item.label).toList();
}

/// A model representing an individual category item in the grid
class CategoryItem {
  final String id;
  final String label;
  final String imagePath;
  final String? description;

  CategoryItem({
    required this.id,
    required this.label,
    required this.imagePath,
    this.description,
  });
}

/// Collection of predefined category groups for the app
class CategoryGroups {
  static final List<CategoryGroup> all = [
    groceryAndKitchen,
    snacksAndDrinks,
    beautyAndPersonalCare,
    fruitsAndVegetables, 
    dairyAndBread,
    bakeriesAndBiscuits,
  ];

  /// Get a subset of category groups by count
  static List<CategoryGroup> getRandomGroups(int count) {
    if (count >= all.length) return all;
    all.shuffle();
    return all.take(count).toList();
  }

  /// Grocery and Kitchen Category Group
  static final CategoryGroup groceryAndKitchen = CategoryGroup(
    id: 'grocery_kitchen',
    title: 'Grocery & Kitchen',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFE1F5E9), // Light green for all items in this category
    items: [
      CategoryItem(
        id: 'vegetables_fruits',
        label: 'Vegetables & Fruits',
        imagePath: '${CategoryAssets.subcategoriesPath}1.png',
      ),
      CategoryItem(
        id: 'atta_rice_dal',
        label: 'Atta, Rice & Dal',
        imagePath: '${CategoryAssets.subcategoriesPath}2.png',
      ),
      CategoryItem(
        id: 'oil_ghee_masala',
        label: 'Oil, Ghee & Masala',
        imagePath: '${CategoryAssets.subcategoriesPath}3.png',
      ),
      CategoryItem(
        id: 'dry_fruits_cereals',
        label: 'Dry Fruits & Cereals',
        imagePath: '${CategoryAssets.subcategoriesPath}4.png',
      ),
      CategoryItem(
        id: 'kitchenware',
        label: 'Kitchenware & Appliances',
        imagePath: '${CategoryAssets.subcategoriesPath}5.png',
      ),
      CategoryItem(
        id: 'instant_food',
        label: 'Instant Food',
        imagePath: '${CategoryAssets.subcategoriesPath}6.png',
      ),
      CategoryItem(
        id: 'sauces_spreads',
        label: 'Sauces & Spreads',
        imagePath: '${CategoryAssets.subcategoriesPath}7.png',
      ),
      CategoryItem(
        id: 'cleaning_household',
        label: 'Cleaning & Household',
        imagePath: '${CategoryAssets.subcategoriesPath}8.png',
      ),
    ],
  );

  /// Snacks and Drinks Category Group
  static final CategoryGroup snacksAndDrinks = CategoryGroup(
    id: 'snacks_drinks',
    title: 'Snacks & Drinks',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFE1F5FE), // Light blue for all items in this category
    items: [
      CategoryItem(
        id: 'chips_namkeen',
        label: 'Chips & Namkeen',
        imagePath: '${CategoryAssets.subcategoriesPath}9.png',
      ),
      CategoryItem(
        id: 'sweets_chocolates',
        label: 'Sweets & Chocolates',
        imagePath: '${CategoryAssets.subcategoriesPath}10.png',
      ),
      CategoryItem(
        id: 'drinks_juices',
        label: 'Drinks & Juices',
        imagePath: '${CategoryAssets.subcategoriesPath}1.png',
      ),
      CategoryItem(
        id: 'tea_coffee_milk',
        label: 'Tea, Coffee & Milk Drinks',
        imagePath: '${CategoryAssets.subcategoriesPath}2.png',
      ),
      CategoryItem(
        id: 'paan_corner',
        label: 'Paan Corner',
        imagePath: '${CategoryAssets.subcategoriesPath}3.png',
      ),
      CategoryItem(
        id: 'ice_cream',
        label: 'Ice Creams & More',
        imagePath: '${CategoryAssets.subcategoriesPath}4.png',
      ),
      CategoryItem(
        id: 'soft_drinks',
        label: 'Soft Drinks',
        imagePath: '${CategoryAssets.subcategoriesPath}5.png',
      ),
      CategoryItem(
        id: 'energy_drinks',
        label: 'Energy Drinks',
        imagePath: '${CategoryAssets.subcategoriesPath}6.png',
      ),
    ],
  );

  /// Beauty and Personal Care Category Group
  static final CategoryGroup beautyAndPersonalCare = CategoryGroup(
    id: 'beauty_personal_care',
    title: 'Beauty & Personal Care',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFF3E5F5), // Light purple for all items in this category
    items: [
      CategoryItem(
        id: 'skin_care',
        label: 'Skin Care',
        imagePath: '${CategoryAssets.subcategoriesPath}7.png',
      ),
      CategoryItem(
        id: 'hair_care',
        label: 'Hair Care',
        imagePath: '${CategoryAssets.subcategoriesPath}8.png',
      ),
      CategoryItem(
        id: 'makeup',
        label: 'Makeup',
        imagePath: '${CategoryAssets.subcategoriesPath}9.png',
      ),
      CategoryItem(
        id: 'fragrances',
        label: 'Fragrances',
        imagePath: '${CategoryAssets.subcategoriesPath}10.png',
      ),
      CategoryItem(
        id: 'men_grooming',
        label: 'Men\'s Grooming',
        imagePath: '${CategoryAssets.subcategoriesPath}1.png',
      ),
      CategoryItem(
        id: 'bath_body',
        label: 'Bath & Body',
        imagePath: '${CategoryAssets.subcategoriesPath}2.png',
      ),
      CategoryItem(
        id: 'feminine_hygiene',
        label: 'Feminine Hygiene',
        imagePath: '${CategoryAssets.subcategoriesPath}3.png',
      ),
      CategoryItem(
        id: 'personal_care',
        label: 'Personal Care',
        imagePath: '${CategoryAssets.subcategoriesPath}4.png',
      ),
    ],
  );

  /// Fruits and Vegetables Category Group
  static final CategoryGroup fruitsAndVegetables = CategoryGroup(
    id: 'fruits_vegetables',
    title: 'Fruits & Vegetables',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFE8F5E9), // Light green for all items in this category
    items: [
      CategoryItem(
        id: 'fresh_fruits',
        label: 'Fresh Fruits',
        imagePath: '${CategoryAssets.subcategoriesPath}5.png',
      ),
      CategoryItem(
        id: 'fresh_vegetables',
        label: 'Fresh Vegetables',
        imagePath: '${CategoryAssets.subcategoriesPath}6.png',
      ),
      CategoryItem(
        id: 'herbs_seasonings',
        label: 'Herbs & Seasonings',
        imagePath: '${CategoryAssets.subcategoriesPath}7.png',
      ),
      CategoryItem(
        id: 'organic',
        label: 'Organic',
        imagePath: '${CategoryAssets.subcategoriesPath}8.png',
      ),
      CategoryItem(
        id: 'exotic_fruits',
        label: 'Exotic Fruits',
        imagePath: '${CategoryAssets.subcategoriesPath}9.png',
      ),
      CategoryItem(
        id: 'exotic_vegetables',
        label: 'Exotic Vegetables',
        imagePath: '${CategoryAssets.subcategoriesPath}10.png',
      ),
      CategoryItem(
        id: 'cut_fruits',
        label: 'Cut & Peeled Fruits',
        imagePath: '${CategoryAssets.subcategoriesPath}1.png',
      ),
      CategoryItem(
        id: 'cut_vegetables',
        label: 'Cut & Peeled Vegetables',
        imagePath: '${CategoryAssets.subcategoriesPath}2.png',
      ),
    ],
  );

  /// Dairy and Bread Category Group
  static final CategoryGroup dairyAndBread = CategoryGroup(
    id: 'dairy_bread',
    title: 'Dairy, Bread & Eggs',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFFFF8E1), // Light amber for all items in this category
    items: [
      CategoryItem(
        id: 'milk',
        label: 'Milk',
        imagePath: '${CategoryAssets.subcategoriesPath}3.png',
      ),
      CategoryItem(
        id: 'bread',
        label: 'Bread',
        imagePath: '${CategoryAssets.subcategoriesPath}4.png',
      ),
      CategoryItem(
        id: 'eggs',
        label: 'Eggs',
        imagePath: '${CategoryAssets.subcategoriesPath}5.png',
      ),
      CategoryItem(
        id: 'butter_cheese',
        label: 'Butter & Cheese',
        imagePath: '${CategoryAssets.subcategoriesPath}6.png',
      ),
      CategoryItem(
        id: 'curd_yogurt',
        label: 'Curd & Yogurt',
        imagePath: '${CategoryAssets.subcategoriesPath}7.png',
      ),
      CategoryItem(
        id: 'paneer_tofu',
        label: 'Paneer & Tofu',
        imagePath: '${CategoryAssets.subcategoriesPath}8.png',
      ),
      CategoryItem(
        id: 'cream_whitener',
        label: 'Cream & Whitener',
        imagePath: '${CategoryAssets.subcategoriesPath}9.png',
      ),
      CategoryItem(
        id: 'condensed_milk',
        label: 'Condensed Milk',
        imagePath: '${CategoryAssets.subcategoriesPath}10.png',
      ),
    ],
  );

  /// Bakeries and Biscuits Category Group
  static final CategoryGroup bakeriesAndBiscuits = CategoryGroup(
    id: 'bakeries_biscuits',
    title: 'Bakery & Biscuits',
    backgroundColor: const Color(0xFF1E1E1E),
    itemBackgroundColor: const Color(0xFFFFECB3), // Light amber/yellow for all items in this category
    items: [
      CategoryItem(
        id: 'cookies',
        label: 'Cookies',
        imagePath: '${CategoryAssets.subcategoriesPath}1.png',
      ),
      CategoryItem(
        id: 'rusk_khari',
        label: 'Rusk & Khari',
        imagePath: '${CategoryAssets.subcategoriesPath}2.png',
      ),
      CategoryItem(
        id: 'cakes_pastries',
        label: 'Cakes & Pastries',
        imagePath: '${CategoryAssets.subcategoriesPath}3.png',
      ),
      CategoryItem(
        id: 'buns_pavs',
        label: 'Buns & Pavs',
        imagePath: '${CategoryAssets.subcategoriesPath}4.png',
      ),
      CategoryItem(
        id: 'premium_cookies',
        label: 'Premium Cookies',
        imagePath: '${CategoryAssets.subcategoriesPath}5.png',
      ),
      CategoryItem(
        id: 'tea_time',
        label: 'Tea Time Biscuits',
        imagePath: '${CategoryAssets.subcategoriesPath}6.png',
      ),
      CategoryItem(
        id: 'cream_biscuits',
        label: 'Cream Biscuits',
        imagePath: '${CategoryAssets.subcategoriesPath}7.png',
      ),
      CategoryItem(
        id: 'bakery_snacks',
        label: 'Bakery Snacks',
        imagePath: '${CategoryAssets.subcategoriesPath}8.png',
      ),
    ],
  );
}