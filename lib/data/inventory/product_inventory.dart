import '../models/product_model.dart';
import '../../core/utils/category_assets.dart';

/// Defines hardcoded product data for each subcategory
/// This can be replaced with real API data in the future
class ProductInventory {
  // Map of subcategory ID to list of products
  static final Map<String, List<ProductModel>> allProducts = {
    // GROCERY & KITCHEN
    'vegetables_fruits': _generateVegetablesFruitsProducts(),
    'atta_rice_dal': _generateAttaRiceDalProducts(),
    'oil_ghee_masala': _generateOilGheeMasalaProducts(),
    'dry_fruits_cereals': _generateDryFruitsCerealsProducts(),
    'kitchenware': _generateKitchenwareProducts(),
    'instant_food': _generateInstantFoodProducts(),
    'sauces_spreads': _generateSaucesSpreadsProducts(),
    'cleaning_household': _generateCleaningHouseholdProducts(),
    
    // SNACKS & DRINKS
    'chips_namkeen': _generateChipsNamkeenProducts(),
    'sweets_chocolates': _generateSweetsChocolatesProducts(),
    'drinks_juices': _generateDrinksJuicesProducts(),
    'tea_coffee_milk': _generateTeaCoffeeMilkProducts(),
    'paan_corner': _generatePaanCornerProducts(),
    'ice_cream': _generateIceCreamProducts(),
    'soft_drinks': _generateSoftDrinksProducts(),
    'energy_drinks': _generateEnergyDrinksProducts(),
    
    // BEAUTY & PERSONAL CARE
    'skin_care': _generateSkinCareProducts(),
    'hair_care': _generateHairCareProducts(),
    'makeup': _generateMakeupProducts(),
    'fragrances': _generateFragrancesProducts(),
    'men_grooming': _generateMenGroomingProducts(),
    'bath_body': _generateBathBodyProducts(),
    'feminine_hygiene': _generateFeminineHygieneProducts(),
    'personal_care': _generatePersonalCareProducts(),
    
    // FRUITS & VEGETABLES
    'fresh_fruits': _generateFreshFruitsProducts(),
    'fresh_vegetables': _generateFreshVegetablesProducts(),
    'herbs_seasonings': _generateHerbsSeasoningsProducts(),
    'organic': _generateOrganicProducts(),
    'exotic_fruits': _generateExoticFruitsProducts(),
    'exotic_vegetables': _generateExoticVegetablesProducts(),
    'cut_fruits': _generateCutFruitsProducts(),
    'cut_vegetables': _generateCutVegetablesProducts(),
    
    // DAIRY, BREAD & EGGS
    'milk': _generateMilkProducts(),
    'bread': _generateBreadProducts(),
    'eggs': _generateEggsProducts(),
    'butter_cheese': _generateButterCheeseProducts(),
    'curd_yogurt': _generateCurdYogurtProducts(),
    'paneer_tofu': _generatePaneerTofuProducts(),
    'cream_whitener': _generateCreamWhitenerProducts(),
    'condensed_milk': _generateCondensedMilkProducts(),
    
    // BAKERY & BISCUITS
    'cookies': _generateCookiesProducts(),
    'rusk_khari': _generateRuskKhariProducts(),
    'cakes_pastries': _generateCakesPastriesProducts(),
    'buns_pavs': _generateBunsPavsProducts(),
    'premium_cookies': _generatePremiumCookiesProducts(),
    'tea_time': _generateTeaTimeBiscuitsProducts(),
    'cream_biscuits': _generateCreamBiscuitsProducts(),
    'bakery_snacks': _generateBakerySnacksProducts(),
  };
  
  /// Get products for a specific subcategory
  static List<ProductModel> getProducts(String subcategoryId) {
    return allProducts[subcategoryId] ?? [];
  }
  
  /// Get all products across all subcategories
  static List<ProductModel> getAllProducts() {
    return allProducts.values.expand((products) => products).toList();
  }
  
  /// Helper function to create a product with common properties
  static ProductModel _createProduct({
    required String id,
    required String name,
    required String subcategoryId,
    required String categoryId,
    required double price,
    double? mrp,
    String? description,
    bool inStock = true,
  }) {
    return ProductModel(
      id: id,
      name: name,
      image: CategoryAssets.getRandomProductImage(),
      description: description ?? 'Quality product from ProfitGrocery',
      price: price,
      mrp: mrp,
      inStock: inStock,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      tags: [subcategoryId],
    );
  }
  
  // GROCERY & KITCHEN
  static List<ProductModel> _generateVegetablesFruitsProducts() {
    return [
      _createProduct(
        id: 'vegetables_fruits_1',
        name: 'Mixed Vegetables Pack',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 199.0,
        description: 'Fresh mixed vegetables pack with potatoes, onions, and tomatoes',
      ),
      _createProduct(
        id: 'vegetables_fruits_2',
        name: 'Seasonal Fruits Basket',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 299.0,
        mrp: 349.0,
        description: 'Seasonal assorted fruits basket with apples, bananas, and oranges',
      ),
      _createProduct(
        id: 'vegetables_fruits_3',
        name: 'Organic Green Vegetables',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 179.0,
        description: 'Fresh organic leafy greens',
      ),
      _createProduct(
        id: 'vegetables_fruits_4',
        name: 'Fresh Carrots 1kg',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_5',
        name: 'Potatoes 2kg',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 45.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_6',
        name: 'Tomatoes 1kg',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 39.0,
        mrp: 49.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_7',
        name: 'Onions 1kg',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 35.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_8',
        name: 'Cucumber 500g',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 29.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_9',
        name: 'Bananas 1 Dozen',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'vegetables_fruits_10',
        name: 'Apples 6pcs',
        subcategoryId: 'vegetables_fruits',
        categoryId: 'grocery_kitchen',
        price: 129.0,
        mrp: 149.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateAttaRiceDalProducts() {
    return [
      _createProduct(
        id: 'atta_rice_dal_1',
        name: 'Premium Wheat Flour 5kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 199.0,
        mrp: 249.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_2',
        name: 'Basmati Rice 5kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 399.0,
        mrp: 449.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_3',
        name: 'Toor Dal 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 139.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_4',
        name: 'Moong Dal 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 129.0,
        mrp: 149.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_5',
        name: 'Chana Dal 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 119.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_6',
        name: 'Masoor Dal 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 109.0,
        mrp: 129.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_7',
        name: 'Brown Rice 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 159.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_8',
        name: 'Multigrain Atta 2kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 179.0,
        mrp: 199.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_9',
        name: 'Sona Masoori Rice 5kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 349.0,
      ),
      _createProduct(
        id: 'atta_rice_dal_10',
        name: 'Urad Dal 1kg',
        subcategoryId: 'atta_rice_dal',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 169.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateOilGheeMasalaProducts() {
    return [
      _createProduct(
        id: 'oil_ghee_masala_1',
        name: 'Refined Sunflower Oil 1L',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_2',
        name: 'Pure Cow Ghee 500ml',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 349.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_3',
        name: 'Garam Masala 100g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 79.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_4',
        name: 'Turmeric Powder 200g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 59.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_5',
        name: 'Chilli Powder 200g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 69.0,
        mrp: 79.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_6',
        name: 'Coriander Powder 200g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 65.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_7',
        name: 'Olive Oil 250ml',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 299.0,
        mrp: 329.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_8',
        name: 'Mustard Oil 1L',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 179.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_9',
        name: 'Kitchen King Masala 100g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'oil_ghee_masala_10',
        name: 'Cumin Powder 100g',
        subcategoryId: 'oil_ghee_masala',
        categoryId: 'grocery_kitchen',
        price: 79.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateDryFruitsCerealsProducts() {
    return [
      _createProduct(
        id: 'dry_fruits_cereals_1',
        name: 'Mixed Dry Fruits 500g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 499.0,
        mrp: 599.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_2',
        name: 'Almonds 250g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 349.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_3',
        name: 'Cashews 250g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 379.0,
        mrp: 429.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_4',
        name: 'Raisins 200g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 119.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_5',
        name: 'Corn Flakes 500g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 179.0,
        mrp: 199.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_6',
        name: 'Muesli 500g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 299.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_7',
        name: 'Oats 1kg',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_8',
        name: 'Walnuts 200g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 299.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_9',
        name: 'Dates 500g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 199.0,
        mrp: 229.0,
      ),
      _createProduct(
        id: 'dry_fruits_cereals_10',
        name: 'Pista 200g',
        subcategoryId: 'dry_fruits_cereals',
        categoryId: 'grocery_kitchen',
        price: 399.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateKitchenwareProducts() {
    return [
      _createProduct(
        id: 'kitchenware_1',
        name: 'Non-stick Pan 24cm',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 699.0,
        mrp: 899.0,
      ),
      _createProduct(
        id: 'kitchenware_2',
        name: 'Stainless Steel Knife Set',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 499.0,
      ),
      _createProduct(
        id: 'kitchenware_3',
        name: 'Chopping Board',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 299.0,
        mrp: 349.0,
      ),
      _createProduct(
        id: 'kitchenware_4',
        name: 'Pressure Cooker 5L',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 1299.0,
      ),
      _createProduct(
        id: 'kitchenware_5',
        name: 'Kitchen Scissors',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 179.0,
      ),
      _createProduct(
        id: 'kitchenware_6',
        name: 'Water Bottle 1L',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 249.0,
      ),
      _createProduct(
        id: 'kitchenware_7',
        name: 'Food Storage Containers',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 399.0,
        mrp: 499.0,
      ),
      _createProduct(
        id: 'kitchenware_8',
        name: 'Measuring Cups Set',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 199.0,
      ),
      _createProduct(
        id: 'kitchenware_9',
        name: 'Stainless Steel Mixing Bowls',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 599.0,
        mrp: 699.0,
      ),
      _createProduct(
        id: 'kitchenware_10',
        name: 'Kitchen Towels (3pcs)',
        subcategoryId: 'kitchenware',
        categoryId: 'grocery_kitchen',
        price: 149.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateInstantFoodProducts() {
    return [
      _createProduct(
        id: 'instant_food_1',
        name: 'Instant Noodles Pack of 5',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'instant_food_2',
        name: 'Ready-to-Eat Dal Makhani',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 119.0,
      ),
      _createProduct(
        id: 'instant_food_3',
        name: 'Instant Poha Mix',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'instant_food_4',
        name: 'Cup Noodles Vegetable',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 49.0,
      ),
      _createProduct(
        id: 'instant_food_5',
        name: 'Instant Upma Mix',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 69.0,
        mrp: 79.0,
      ),
      _createProduct(
        id: 'instant_food_6',
        name: 'Ready-to-Eat Paneer Butter Masala',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 129.0,
      ),
      _createProduct(
        id: 'instant_food_7',
        name: 'Instant Soup Mix',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'instant_food_8',
        name: 'Ready-to-Eat Biryani',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 149.0,
      ),
      _createProduct(
        id: 'instant_food_9',
        name: 'Instant Pasta',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'instant_food_10',
        name: 'Cup Soup Tomato',
        subcategoryId: 'instant_food',
        categoryId: 'grocery_kitchen',
        price: 39.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateSaucesSpreadsProducts() {
    return [
      _createProduct(
        id: 'sauces_spreads_1',
        name: 'Tomato Ketchup 1kg',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 129.0,
        mrp: 149.0,
      ),
      _createProduct(
        id: 'sauces_spreads_2',
        name: 'Mayonnaise 500g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 179.0,
      ),
      _createProduct(
        id: 'sauces_spreads_3',
        name: 'Peanut Butter 340g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 199.0,
        mrp: 229.0,
      ),
      _createProduct(
        id: 'sauces_spreads_4',
        name: 'Chocolate Spread 350g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 249.0,
      ),
      _createProduct(
        id: 'sauces_spreads_5',
        name: 'Chilli Sauce 200g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'sauces_spreads_6',
        name: 'Honey 500g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 299.0,
      ),
      _createProduct(
        id: 'sauces_spreads_7',
        name: 'Soy Sauce 200ml',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'sauces_spreads_8',
        name: 'Jam Mixed Fruit 500g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 119.0,
      ),
      _createProduct(
        id: 'sauces_spreads_9',
        name: 'Pasta Sauce 325g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 159.0,
        mrp: 179.0,
      ),
      _createProduct(
        id: 'sauces_spreads_10',
        name: 'Cheese Spread 200g',
        subcategoryId: 'sauces_spreads',
        categoryId: 'grocery_kitchen',
        price: 129.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCleaningHouseholdProducts() {
    return [
      _createProduct(
        id: 'cleaning_household_1',
        name: 'Dish Washing Liquid 500ml',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'cleaning_household_2',
        name: 'Floor Cleaner 1L',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 149.0,
      ),
      _createProduct(
        id: 'cleaning_household_3',
        name: 'Bathroom Cleaner 500ml',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 119.0,
        mrp: 139.0,
      ),
      _createProduct(
        id: 'cleaning_household_4',
        name: 'Glass Cleaner 500ml',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 99.0,
      ),
      _createProduct(
        id: 'cleaning_household_5',
        name: 'Toilet Cleaner 500ml',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'cleaning_household_6',
        name: 'Microfiber Cloth Set',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 199.0,
      ),
      _createProduct(
        id: 'cleaning_household_7',
        name: 'Detergent Powder 1kg',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 179.0,
        mrp: 199.0,
      ),
      _createProduct(
        id: 'cleaning_household_8',
        name: 'Dishwashing Bar 3pcs',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 69.0,
      ),
      _createProduct(
        id: 'cleaning_household_9',
        name: 'Mop with Bucket',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 499.0,
        mrp: 599.0,
      ),
      _createProduct(
        id: 'cleaning_household_10',
        name: 'Garbage Bags (30pcs)',
        subcategoryId: 'cleaning_household',
        categoryId: 'grocery_kitchen',
        price: 79.0,
      ),
    ];
  }
  
  // SNACKS & DRINKS
  static List<ProductModel> _generateChipsNamkeenProducts() {
    return [
      _createProduct(
        id: 'chips_namkeen_1',
        name: 'Potato Chips Classic 100g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 30.0,
        mrp: 35.0,
      ),
      _createProduct(
        id: 'chips_namkeen_2',
        name: 'Mixture 200g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 45.0,
      ),
      _createProduct(
        id: 'chips_namkeen_3',
        name: 'Aloo Bhujia 200g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 49.0,
        mrp: 55.0,
      ),
      _createProduct(
        id: 'chips_namkeen_4',
        name: 'Moong Dal 150g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 39.0,
      ),
      _createProduct(
        id: 'chips_namkeen_5',
        name: 'Masala Peanuts 200g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 55.0,
        mrp: 65.0,
      ),
      _createProduct(
        id: 'chips_namkeen_6',
        name: 'Baked Chips 100g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 40.0,
      ),
      _createProduct(
        id: 'chips_namkeen_7',
        name: 'Sev 200g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 49.0,
        mrp: 55.0,
      ),
      _createProduct(
        id: 'chips_namkeen_8',
        name: 'Chana Jor 200g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 59.0,
      ),
      _createProduct(
        id: 'chips_namkeen_9',
        name: 'Cheese Balls 100g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 45.0,
        mrp: 50.0,
      ),
      _createProduct(
        id: 'chips_namkeen_10',
        name: 'Banana Chips 150g',
        subcategoryId: 'chips_namkeen',
        categoryId: 'snacks_drinks',
        price: 69.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateSweetsChocolatesProducts() {
    return [
      _createProduct(
        id: 'sweets_chocolates_1',
        name: 'Milk Chocolate 100g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_2',
        name: 'Rasgulla Tin 1kg',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 249.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_3',
        name: 'Soan Papdi 500g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 189.0,
        mrp: 209.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_4',
        name: 'Gulab Jamun Mix 500g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 119.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_5',
        name: 'Chocolate Gift Box 200g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 299.0,
        mrp: 349.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_6',
        name: 'Jelly Beans 100g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 79.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_7',
        name: 'Barfi 500g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 219.0,
        mrp: 249.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_8',
        name: 'Dark Chocolate 100g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 149.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_9',
        name: 'Chewing Gum Pack',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 20.0,
        mrp: 25.0,
      ),
      _createProduct(
        id: 'sweets_chocolates_10',
        name: 'Hard Candies Mix 250g',
        subcategoryId: 'sweets_chocolates',
        categoryId: 'snacks_drinks',
        price: 89.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateDrinksJuicesProducts() {
    return [
      _createProduct(
        id: 'drinks_juices_1',
        name: 'Orange Juice 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'drinks_juices_2',
        name: 'Mixed Fruit Juice 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 109.0,
      ),
      _createProduct(
        id: 'drinks_juices_3',
        name: 'Cranberry Juice 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'drinks_juices_4',
        name: 'Apple Juice 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 119.0,
      ),
      _createProduct(
        id: 'drinks_juices_5',
        name: 'Mango Drink 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'drinks_juices_6',
        name: 'Fruit Punch 500ml',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 59.0,
      ),
      _createProduct(
        id: 'drinks_juices_7',
        name: 'Coconut Water 200ml',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 35.0,
        mrp: 40.0,
      ),
      _createProduct(
        id: 'drinks_juices_8',
        name: 'Lemonade 500ml',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 45.0,
      ),
      _createProduct(
        id: 'drinks_juices_9',
        name: 'Grape Juice 1L',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 129.0,
        mrp: 149.0,
      ),
      _createProduct(
        id: 'drinks_juices_10',
        name: 'Fruit Juice Box Pack (6pcs)',
        subcategoryId: 'drinks_juices',
        categoryId: 'snacks_drinks',
        price: 120.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateTeaCoffeeMilkProducts() {
    return [
      _createProduct(
        id: 'tea_coffee_milk_1',
        name: 'Premium Tea 250g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_2',
        name: 'Instant Coffee 100g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 249.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_3',
        name: 'Green Tea 25 Bags',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 169.0,
        mrp: 199.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_4',
        name: 'Chocolate Milk Mix 500g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 199.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_5',
        name: 'Masala Tea 100g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_6',
        name: 'Coffee Beans 250g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 349.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_7',
        name: 'Herbal Tea 20 Bags',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 189.0,
        mrp: 209.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_8',
        name: 'Flavored Coffee 100g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 279.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_9',
        name: 'Milk Powder 500g',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 229.0,
        mrp: 249.0,
      ),
      _createProduct(
        id: 'tea_coffee_milk_10',
        name: 'Tea Premix 1kg',
        subcategoryId: 'tea_coffee_milk',
        categoryId: 'snacks_drinks',
        price: 399.0,
      ),
    ];
  }
  
  static List<ProductModel> _generatePaanCornerProducts() {
    return [
      _createProduct(
        id: 'paan_corner_1',
        name: 'Meetha Paan',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 25.0,
      ),
      _createProduct(
        id: 'paan_corner_2',
        name: 'Saada Paan',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 15.0,
      ),
      _createProduct(
        id: 'paan_corner_3',
        name: 'Chocolate Paan',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 35.0,
        mrp: 40.0,
      ),
      _createProduct(
        id: 'paan_corner_4',
        name: 'Fire Paan',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 40.0,
      ),
      _createProduct(
        id: 'paan_corner_5',
        name: 'Ice Paan',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 40.0,
        mrp: 45.0,
      ),
      _createProduct(
        id: 'paan_corner_6',
        name: 'Mitha Supari 100g',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 59.0,
      ),
      _createProduct(
        id: 'paan_corner_7',
        name: 'Saunf Mix 100g',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 49.0,
        mrp: 59.0,
      ),
      _createProduct(
        id: 'paan_corner_8',
        name: 'Paan Masala 10g',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 25.0,
      ),
      _createProduct(
        id: 'paan_corner_9',
        name: 'Gulkand 200g',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'paan_corner_10',
        name: 'Mouth Freshener 50g',
        subcategoryId: 'paan_corner',
        categoryId: 'snacks_drinks',
        price: 45.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateIceCreamProducts() {
    return [
      _createProduct(
        id: 'ice_cream_1',
        name: 'Vanilla Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 199.0,
        mrp: 229.0,
      ),
      _createProduct(
        id: 'ice_cream_2',
        name: 'Chocolate Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 219.0,
      ),
      _createProduct(
        id: 'ice_cream_3',
        name: 'Strawberry Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 209.0,
        mrp: 239.0,
      ),
      _createProduct(
        id: 'ice_cream_4',
        name: 'Butterscotch Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 229.0,
      ),
      _createProduct(
        id: 'ice_cream_5',
        name: 'Mango Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 219.0,
        mrp: 249.0,
      ),
      _createProduct(
        id: 'ice_cream_6',
        name: 'Ice Cream Cones (10pcs)',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 129.0,
      ),
      _createProduct(
        id: 'ice_cream_7',
        name: 'Ice Cream Sticks (6pcs)',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 199.0,
        mrp: 229.0,
      ),
      _createProduct(
        id: 'ice_cream_8',
        name: 'Kesar Pista Ice Cream 1L',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 249.0,
      ),
      _createProduct(
        id: 'ice_cream_9',
        name: 'Kulfi (4pcs)',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 159.0,
        mrp: 179.0,
      ),
      _createProduct(
        id: 'ice_cream_10',
        name: 'Ice Cream Cake 500g',
        subcategoryId: 'ice_cream',
        categoryId: 'snacks_drinks',
        price: 349.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateSoftDrinksProducts() {
    return [
      _createProduct(
        id: 'soft_drinks_1',
        name: 'Cola 2L',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 85.0,
        mrp: 95.0,
      ),
      _createProduct(
        id: 'soft_drinks_2',
        name: 'Lemon Soda 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 65.0,
      ),
      _createProduct(
        id: 'soft_drinks_3',
        name: 'Orange Soda 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 65.0,
        mrp: 75.0,
      ),
      _createProduct(
        id: 'soft_drinks_4',
        name: 'Cola Can (6pcs)',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 180.0,
      ),
      _createProduct(
        id: 'soft_drinks_5',
        name: 'Diet Cola 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 70.0,
        mrp: 80.0,
      ),
      _createProduct(
        id: 'soft_drinks_6',
        name: 'Clear Lemon 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 60.0,
      ),
      _createProduct(
        id: 'soft_drinks_7',
        name: 'Ginger Ale 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 75.0,
        mrp: 85.0,
      ),
      _createProduct(
        id: 'soft_drinks_8',
        name: 'Tonic Water 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 80.0,
      ),
      _createProduct(
        id: 'soft_drinks_9',
        name: 'Soda Water 750ml',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 50.0,
        mrp: 60.0,
      ),
      _createProduct(
        id: 'soft_drinks_10',
        name: 'Flavored Soda Pack (4 cans)',
        subcategoryId: 'soft_drinks',
        categoryId: 'snacks_drinks',
        price: 140.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateEnergyDrinksProducts() {
    return [
      _createProduct(
        id: 'energy_drinks_1',
        name: 'Energy Drink 250ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 99.0,
        mrp: 109.0,
      ),
      _createProduct(
        id: 'energy_drinks_2',
        name: 'Sports Drink 500ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 75.0,
      ),
      _createProduct(
        id: 'energy_drinks_3',
        name: 'Glucose Water 500ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 30.0,
        mrp: 35.0,
      ),
      _createProduct(
        id: 'energy_drinks_4',
        name: 'Energy Drink 4 Pack',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 359.0,
      ),
      _createProduct(
        id: 'energy_drinks_5',
        name: 'Protein Shake 250ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 129.0,
        mrp: 149.0,
      ),
      _createProduct(
        id: 'energy_drinks_6',
        name: 'Electrolyte Drink 500ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 89.0,
      ),
      _createProduct(
        id: 'energy_drinks_7',
        name: 'Pre-Workout Drink 330ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 159.0,
        mrp: 179.0,
      ),
      _createProduct(
        id: 'energy_drinks_8',
        name: 'Recovery Drink 500ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 119.0,
      ),
      _createProduct(
        id: 'energy_drinks_9',
        name: 'Vitamin Water 500ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'energy_drinks_10',
        name: 'Sugar-Free Energy Drink 250ml',
        subcategoryId: 'energy_drinks',
        categoryId: 'snacks_drinks',
        price: 109.0,
      ),
    ];
  }
  
  // BEAUTY & PERSONAL CARE - Placeholder implementations (adding 1-2 products per category for brevity)
  static List<ProductModel> _generateSkinCareProducts() {
    return [
      _createProduct(
        id: 'skin_care_1',
        name: 'Face Wash 150ml',
        subcategoryId: 'skin_care',
        categoryId: 'beauty_personal_care',
        price: 199.0,
        mrp: 249.0,
      ),
      _createProduct(
        id: 'skin_care_2',
        name: 'Moisturizer 100ml',
        subcategoryId: 'skin_care',
        categoryId: 'beauty_personal_care',
        price: 249.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateHairCareProducts() {
    return [
      _createProduct(
        id: 'hair_care_1',
        name: 'Shampoo 300ml',
        subcategoryId: 'hair_care',
        categoryId: 'beauty_personal_care',
        price: 179.0,
        mrp: 199.0,
      ),
      _createProduct(
        id: 'hair_care_2',
        name: 'Hair Oil 200ml',
        subcategoryId: 'hair_care',
        categoryId: 'beauty_personal_care',
        price: 159.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateMakeupProducts() {
    return [
      _createProduct(
        id: 'makeup_1',
        name: 'Lipstick',
        subcategoryId: 'makeup',
        categoryId: 'beauty_personal_care',
        price: 299.0,
        mrp: 349.0,
      ),
      _createProduct(
        id: 'makeup_2',
        name: 'Foundation',
        subcategoryId: 'makeup',
        categoryId: 'beauty_personal_care',
        price: 349.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateFragrancesProducts() {
    return [
      _createProduct(
        id: 'fragrances_1',
        name: 'Perfume 50ml',
        subcategoryId: 'fragrances',
        categoryId: 'beauty_personal_care',
        price: 499.0,
        mrp: 599.0,
      ),
      _createProduct(
        id: 'fragrances_2',
        name: 'Body Mist 200ml',
        subcategoryId: 'fragrances',
        categoryId: 'beauty_personal_care',
        price: 299.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateMenGroomingProducts() {
    return [
      _createProduct(
        id: 'men_grooming_1',
        name: 'Shaving Cream 100g',
        subcategoryId: 'men_grooming',
        categoryId: 'beauty_personal_care',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'men_grooming_2',
        name: 'Beard Oil 30ml',
        subcategoryId: 'men_grooming',
        categoryId: 'beauty_personal_care',
        price: 249.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateBathBodyProducts() {
    return [
      _createProduct(
        id: 'bath_body_1',
        name: 'Body Wash 250ml',
        subcategoryId: 'bath_body',
        categoryId: 'beauty_personal_care',
        price: 199.0,
        mrp: 229.0,
      ),
      _createProduct(
        id: 'bath_body_2',
        name: 'Bath Soap (3pcs)',
        subcategoryId: 'bath_body',
        categoryId: 'beauty_personal_care',
        price: 129.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateFeminineHygieneProducts() {
    return [
      _createProduct(
        id: 'feminine_hygiene_1',
        name: 'Sanitary Pads (10pcs)',
        subcategoryId: 'feminine_hygiene',
        categoryId: 'beauty_personal_care',
        price: 149.0,
        mrp: 169.0,
      ),
      _createProduct(
        id: 'feminine_hygiene_2',
        name: 'Intimate Wash 200ml',
        subcategoryId: 'feminine_hygiene',
        categoryId: 'beauty_personal_care',
        price: 199.0,
      ),
    ];
  }
  
  static List<ProductModel> _generatePersonalCareProducts() {
    return [
      _createProduct(
        id: 'personal_care_1',
        name: 'Toothpaste 150g',
        subcategoryId: 'personal_care',
        categoryId: 'beauty_personal_care',
        price: 99.0,
        mrp: 109.0,
      ),
      _createProduct(
        id: 'personal_care_2',
        name: 'Hand Sanitizer 250ml',
        subcategoryId: 'personal_care',
        categoryId: 'beauty_personal_care',
        price: 129.0,
      ),
    ];
  }
  
  // FRUITS & VEGETABLES - Placeholder implementations
  static List<ProductModel> _generateFreshFruitsProducts() {
    return [
      _createProduct(
        id: 'fresh_fruits_1',
        name: 'Apples 1kg',
        subcategoryId: 'fresh_fruits',
        categoryId: 'fruits_vegetables',
        price: 199.0,
        mrp: 219.0,
      ),
      _createProduct(
        id: 'fresh_fruits_2',
        name: 'Bananas 1kg',
        subcategoryId: 'fresh_fruits',
        categoryId: 'fruits_vegetables',
        price: 59.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateFreshVegetablesProducts() {
    return [
      _createProduct(
        id: 'fresh_vegetables_1',
        name: 'Tomatoes 1kg',
        subcategoryId: 'fresh_vegetables',
        categoryId: 'fruits_vegetables',
        price: 39.0,
        mrp: 49.0,
      ),
      _createProduct(
        id: 'fresh_vegetables_2',
        name: 'Potatoes 1kg',
        subcategoryId: 'fresh_vegetables',
        categoryId: 'fruits_vegetables',
        price: 29.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateHerbsSeasoningsProducts() {
    return [
      _createProduct(
        id: 'herbs_seasonings_1',
        name: 'Coriander Bunch',
        subcategoryId: 'herbs_seasonings',
        categoryId: 'fruits_vegetables',
        price: 19.0,
      ),
      _createProduct(
        id: 'herbs_seasonings_2',
        name: 'Mint Bunch',
        subcategoryId: 'herbs_seasonings',
        categoryId: 'fruits_vegetables',
        price: 19.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateOrganicProducts() {
    return [
      _createProduct(
        id: 'organic_1',
        name: 'Organic Spinach 250g',
        subcategoryId: 'organic',
        categoryId: 'fruits_vegetables',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'organic_2',
        name: 'Organic Carrots 500g',
        subcategoryId: 'organic',
        categoryId: 'fruits_vegetables',
        price: 79.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateExoticFruitsProducts() {
    return [
      _createProduct(
        id: 'exotic_fruits_1',
        name: 'Kiwi 3pcs',
        subcategoryId: 'exotic_fruits',
        categoryId: 'fruits_vegetables',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'exotic_fruits_2',
        name: 'Dragon Fruit 1pc',
        subcategoryId: 'exotic_fruits',
        categoryId: 'fruits_vegetables',
        price: 149.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateExoticVegetablesProducts() {
    return [
      _createProduct(
        id: 'exotic_vegetables_1',
        name: 'Broccoli 500g',
        subcategoryId: 'exotic_vegetables',
        categoryId: 'fruits_vegetables',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'exotic_vegetables_2',
        name: 'Bell Peppers 500g',
        subcategoryId: 'exotic_vegetables',
        categoryId: 'fruits_vegetables',
        price: 89.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCutFruitsProducts() {
    return [
      _createProduct(
        id: 'cut_fruits_1',
        name: 'Cut Pineapple 250g',
        subcategoryId: 'cut_fruits',
        categoryId: 'fruits_vegetables',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'cut_fruits_2',
        name: 'Mixed Fruit Bowl 300g',
        subcategoryId: 'cut_fruits',
        categoryId: 'fruits_vegetables',
        price: 129.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCutVegetablesProducts() {
    return [
      _createProduct(
        id: 'cut_vegetables_1',
        name: 'Cut Mixed Vegetables 300g',
        subcategoryId: 'cut_vegetables',
        categoryId: 'fruits_vegetables',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'cut_vegetables_2',
        name: 'Chopped Onions 200g',
        subcategoryId: 'cut_vegetables',
        categoryId: 'fruits_vegetables',
        price: 39.0,
      ),
    ];
  }
  
  // DAIRY, BREAD & EGGS - Placeholder implementations
  static List<ProductModel> _generateMilkProducts() {
    return [
      _createProduct(
        id: 'milk_1',
        name: 'Full Cream Milk 1L',
        subcategoryId: 'milk',
        categoryId: 'dairy_bread',
        price: 60.0,
        mrp: 65.0,
      ),
      _createProduct(
        id: 'milk_2',
        name: 'Toned Milk 1L',
        subcategoryId: 'milk',
        categoryId: 'dairy_bread',
        price: 55.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateBreadProducts() {
    return [
      _createProduct(
        id: 'bread_1',
        name: 'White Bread 400g',
        subcategoryId: 'bread',
        categoryId: 'dairy_bread',
        price: 40.0,
        mrp: 45.0,
      ),
      _createProduct(
        id: 'bread_2',
        name: 'Brown Bread 400g',
        subcategoryId: 'bread',
        categoryId: 'dairy_bread',
        price: 45.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateEggsProducts() {
    return [
      _createProduct(
        id: 'eggs_1',
        name: 'Regular Eggs (12pcs)',
        subcategoryId: 'eggs',
        categoryId: 'dairy_bread',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'eggs_2',
        name: 'Brown Eggs (6pcs)',
        subcategoryId: 'eggs',
        categoryId: 'dairy_bread',
        price: 59.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateButterCheeseProducts() {
    return [
      _createProduct(
        id: 'butter_cheese_1',
        name: 'Butter 100g',
        subcategoryId: 'butter_cheese',
        categoryId: 'dairy_bread',
        price: 49.0,
        mrp: 55.0,
      ),
      _createProduct(
        id: 'butter_cheese_2',
        name: 'Cheese Slices 10pcs',
        subcategoryId: 'butter_cheese',
        categoryId: 'dairy_bread',
        price: 129.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCurdYogurtProducts() {
    return [
      _createProduct(
        id: 'curd_yogurt_1',
        name: 'Plain Curd 400g',
        subcategoryId: 'curd_yogurt',
        categoryId: 'dairy_bread',
        price: 45.0,
        mrp: 50.0,
      ),
      _createProduct(
        id: 'curd_yogurt_2',
        name: 'Fruit Yogurt 100g',
        subcategoryId: 'curd_yogurt',
        categoryId: 'dairy_bread',
        price: 35.0,
      ),
    ];
  }
  
  static List<ProductModel> _generatePaneerTofuProducts() {
    return [
      _createProduct(
        id: 'paneer_tofu_1',
        name: 'Fresh Paneer 200g',
        subcategoryId: 'paneer_tofu',
        categoryId: 'dairy_bread',
        price: 89.0,
        mrp: 99.0,
      ),
      _createProduct(
        id: 'paneer_tofu_2',
        name: 'Tofu 200g',
        subcategoryId: 'paneer_tofu',
        categoryId: 'dairy_bread',
        price: 79.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCreamWhitenerProducts() {
    return [
      _createProduct(
        id: 'cream_whitener_1',
        name: 'Fresh Cream 200ml',
        subcategoryId: 'cream_whitener',
        categoryId: 'dairy_bread',
        price: 69.0,
        mrp: 79.0,
      ),
      _createProduct(
        id: 'cream_whitener_2',
        name: 'Dairy Whitener 400g',
        subcategoryId: 'cream_whitener',
        categoryId: 'dairy_bread',
        price: 199.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCondensedMilkProducts() {
    return [
      _createProduct(
        id: 'condensed_milk_1',
        name: 'Condensed Milk 400g',
        subcategoryId: 'condensed_milk',
        categoryId: 'dairy_bread',
        price: 129.0,
        mrp: 139.0,
      ),
      _createProduct(
        id: 'condensed_milk_2',
        name: 'Sweetened Condensed Milk 200g',
        subcategoryId: 'condensed_milk',
        categoryId: 'dairy_bread',
        price: 79.0,
      ),
    ];
  }
  
  // BAKERY & BISCUITS - Placeholder implementations
  static List<ProductModel> _generateCookiesProducts() {
    return [
      _createProduct(
        id: 'cookies_1',
        name: 'Chocolate Cookies 300g',
        subcategoryId: 'cookies',
        categoryId: 'bakeries_biscuits',
        price: 99.0,
        mrp: 119.0,
      ),
      _createProduct(
        id: 'cookies_2',
        name: 'Butter Cookies 250g',
        subcategoryId: 'cookies',
        categoryId: 'bakeries_biscuits',
        price: 89.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateRuskKhariProducts() {
    return [
      _createProduct(
        id: 'rusk_khari_1',
        name: 'Rusk 300g',
        subcategoryId: 'rusk_khari',
        categoryId: 'bakeries_biscuits',
        price: 59.0,
        mrp: 69.0,
      ),
      _createProduct(
        id: 'rusk_khari_2',
        name: 'Khari 200g',
        subcategoryId: 'rusk_khari',
        categoryId: 'bakeries_biscuits',
        price: 69.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCakesPastriesProducts() {
    return [
      _createProduct(
        id: 'cakes_pastries_1',
        name: 'Chocolate Cake 500g',
        subcategoryId: 'cakes_pastries',
        categoryId: 'bakeries_biscuits',
        price: 299.0,
        mrp: 349.0,
      ),
      _createProduct(
        id: 'cakes_pastries_2',
        name: 'Vanilla Pastry 2pcs',
        subcategoryId: 'cakes_pastries',
        categoryId: 'bakeries_biscuits',
        price: 99.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateBunsPavsProducts() {
    return [
      _createProduct(
        id: 'buns_pavs_1',
        name: 'Burger Buns 4pcs',
        subcategoryId: 'buns_pavs',
        categoryId: 'bakeries_biscuits',
        price: 45.0,
        mrp: 50.0,
      ),
      _createProduct(
        id: 'buns_pavs_2',
        name: 'Pav 6pcs',
        subcategoryId: 'buns_pavs',
        categoryId: 'bakeries_biscuits',
        price: 30.0,
      ),
    ];
  }
  
  static List<ProductModel> _generatePremiumCookiesProducts() {
    return [
      _createProduct(
        id: 'premium_cookies_1',
        name: 'Assorted Premium Cookies 400g',
        subcategoryId: 'premium_cookies',
        categoryId: 'bakeries_biscuits',
        price: 299.0,
        mrp: 349.0,
      ),
      _createProduct(
        id: 'premium_cookies_2',
        name: 'Almond Cookies 250g',
        subcategoryId: 'premium_cookies',
        categoryId: 'bakeries_biscuits',
        price: 249.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateTeaTimeBiscuitsProducts() {
    return [
      _createProduct(
        id: 'tea_time_1',
        name: 'Marie Biscuits 300g',
        subcategoryId: 'tea_time',
        categoryId: 'bakeries_biscuits',
        price: 49.0,
        mrp: 55.0,
      ),
      _createProduct(
        id: 'tea_time_2',
        name: 'Glucose Biscuits 300g',
        subcategoryId: 'tea_time',
        categoryId: 'bakeries_biscuits',
        price: 39.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateCreamBiscuitsProducts() {
    return [
      _createProduct(
        id: 'cream_biscuits_1',
        name: 'Chocolate Cream Biscuits 120g',
        subcategoryId: 'cream_biscuits',
        categoryId: 'bakeries_biscuits',
        price: 39.0,
        mrp: 45.0,
      ),
      _createProduct(
        id: 'cream_biscuits_2',
        name: 'Vanilla Cream Biscuits 120g',
        subcategoryId: 'cream_biscuits',
        categoryId: 'bakeries_biscuits',
        price: 35.0,
      ),
    ];
  }
  
  static List<ProductModel> _generateBakerySnacksProducts() {
    return [
      _createProduct(
        id: 'bakery_snacks_1',
        name: 'Bread Sticks 150g',
        subcategoryId: 'bakery_snacks',
        categoryId: 'bakeries_biscuits',
        price: 79.0,
        mrp: 89.0,
      ),
      _createProduct(
        id: 'bakery_snacks_2',
        name: 'Cheese Puffs 200g',
        subcategoryId: 'bakery_snacks',
        categoryId: 'bakeries_biscuits',
        price: 99.0,
      ),
    ];
  }
}
