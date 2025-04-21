import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/inventory/bestseller_products.dart';
import '../../../data/inventory/product_inventory.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/category_group_model.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../data/repositories/category_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CategoryRepository _categoryRepository;

  HomeBloc({CategoryRepository? categoryRepository}) 
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<SelectCategoryTab>(_onSelectCategoryTab);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
    on<UpdateHomeCartData>(_onUpdateHomeCartData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      
      // Generate subcategory colors
      final Map<String, Color> subcategoryColors = _generateSubcategoryColors();

      // In a real app, we would fetch this data from repositories
      // For now, we'll use mock data
      final tabs = _getMockTabs();
      final banners = _getMockBanners();
      
      // Get all category types
      final allCategories = _getMockCategories();
      final mainCategories = allCategories.where((c) => 
          c.id.startsWith('grocery_') || c.id.startsWith('kitchen_')).toList();
      final snacksCategories = allCategories.where((c) => 
          c.id.startsWith('snacks_')).toList();
      final storeCategories = allCategories.where((c) => 
          c.type == AppConstants.storeCategoryType).toList();
      final featuredPromotions = allCategories.where((c) => 
          c.type == AppConstants.promotionalCategoryType).toList();
          
      // Get products
      final featuredProducts = _getMockFeaturedProducts();
      final newArrivals = _getMockNewArrivals();
      
      // Note: We no longer need to load bestsellers here
      // They are loaded directly by the SmartBestsellerGrid widget
      
      // Get cart data
      final cartQuantities = _getMockCartQuantities();
      final cartItemCount = cartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
      const cartPreviewImage = '${AppConstants.assetsProductsPath}1.png'; // First product in cart
      final cartTotalAmount = _calculateCartTotal(cartQuantities);

      // Get category groups for 4x2 grid widget
      final categoryGroups = await _categoryRepository.fetchCategories();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        status: HomeStatus.loaded,
        tabs: tabs,
        banners: banners,
        mainCategories: mainCategories,
        snacksCategories: snacksCategories,
        storeCategories: storeCategories,
        featuredPromotions: featuredPromotions,
        cartItemCount: cartItemCount,
        cartPreviewImage: cartPreviewImage,
        cartTotalAmount: cartTotalAmount,
        cartQuantities: cartQuantities,
        categoryGroups: categoryGroups,
        subcategoryColors: subcategoryColors,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to load home data: $e',
      ));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Load categories from Firestore
      final categoryGroups = await _categoryRepository.fetchCategories();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        categoryGroups: categoryGroups,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to refresh home data: $e',
      ));
    }
  }

  void _onSelectCategoryTab(
    SelectCategoryTab event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }
  
  void _onUpdateCartQuantity(
    UpdateCartQuantity event,
    Emitter<HomeState> emit,
  ) {
    final product = event.product;
    final quantity = event.quantity;
    
    CartLogger.log('HOME_BLOC', 'Updating cart quantity for product: ${product.name} (${product.id}), new quantity: $quantity');
    
    // Update cart quantities
    final updatedCartQuantities = Map<String, int>.from(state.cartQuantities);
    
    if (quantity <= 0) {
      CartLogger.info('HOME_BLOC', 'Removing product from cart: ${product.id}');
      updatedCartQuantities.remove(product.id);
    } else {
      CartLogger.info('HOME_BLOC', 'Setting product quantity in cart: ${product.id} = $quantity');
      updatedCartQuantities[product.id] = quantity;
    }
    
    // Calculate new cart total and count
    final cartItemCount = updatedCartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
    
    CartLogger.info('HOME_BLOC', 'Updated cart summary - items: $cartItemCount, total: $cartTotalAmount');
    CartLogger.info('HOME_BLOC', 'Cart quantities: $updatedCartQuantities');
    
    // Choose the first product in cart for preview, or null if cart empty
    String? cartPreviewImage;
    if (updatedCartQuantities.isNotEmpty) {
      final previewProductId = updatedCartQuantities.keys.first;
      // In a real app, we'd look up the product image from repository
      cartPreviewImage = '${AppConstants.assetsProductsPath}1.png';
      CartLogger.info('HOME_BLOC', 'Cart preview image set to: $cartPreviewImage');
    } else {
      CartLogger.info('HOME_BLOC', 'No cart preview image (cart is empty)');
    }
    
    emit(state.copyWith(
      cartQuantities: updatedCartQuantities,
      cartItemCount: cartItemCount,
      cartTotalAmount: cartTotalAmount,
      cartPreviewImage: cartPreviewImage,
    ));
    
    CartLogger.success('HOME_BLOC', 'Cart state updated successfully');
  }
  
  void _onUpdateHomeCartData(
    UpdateHomeCartData event,
    Emitter<HomeState> emit,
  ) {
    CartLogger.log('HOME_BLOC', 'Updating cart data from CartBloc sync');
    CartLogger.info('HOME_BLOC', 'Cart data: items: ${event.cartItemCount}, total: ${event.cartTotalAmount}');
    CartLogger.info('HOME_BLOC', 'Cart quantities: ${event.cartQuantities}');
    
    emit(state.copyWith(
      cartQuantities: event.cartQuantities,
      cartItemCount: event.cartItemCount,
      cartTotalAmount: event.cartTotalAmount,
      cartPreviewImage: event.cartPreviewImage,
    ));
    
    CartLogger.success('HOME_BLOC', 'Cart data updated from CartBloc sync');
  }
  
  // Calculate total cart value
  double _calculateCartTotal(Map<String, int> cartQuantities) {
    double total = 0.0;
    
    // In a real app, we'd use a repository to get product prices
    // For demo, use mock price of ₹100 per item
    cartQuantities.forEach((productId, quantity) {
      total += 100.0 * quantity;
    });
    
    return total;
  }

  // Mock data methods
  List<String> _getMockTabs() {
    return [
      'All',
      'Electronics',
      'Beauty',
      'Kids',
      'Gifting',
    ];
  }

  List<String> _getMockBanners() {
    return [
      '${AppConstants.assetsImagesPath}gift.jpg',
      '${AppConstants.assetsCimgsPath}1.jpg',
      '${AppConstants.assetsCimgsPath}2.jpg',
      '${AppConstants.assetsCimgsPath}3.jpg',
      '${AppConstants.assetsCimgsPath}4.jpg',
    ];
  }

  List<Category> _getMockCategories() {
    return [
      // Grocery & Kitchen Categories
      Category(
        id: 'grocery_1',
        name: 'Vegetables & Fruits',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'grocery_2',
        name: 'Atta, Rice & Dal',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'grocery_3',
        name: 'Oil, Ghee & Masala',
        image: '${AppConstants.assetsCategoriesPath}3.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'grocery_4',
        name: 'Dairy, Bread & Eggs',
        image: '${AppConstants.assetsCategoriesPath}4.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'kitchen_1',
        name: 'Bakery & Biscuits',
        image: '${AppConstants.assetsCategoriesPath}5.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'kitchen_2',
        name: 'Dry Fruits & Cereals',
        image: '${AppConstants.assetsCategoriesPath}6.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'kitchen_3',
        name: 'Chicken, Meat & Fish',
        image: '${AppConstants.assetsCategoriesPath}7.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'kitchen_4',
        name: 'Kitchenware & Appliances',
        image: '${AppConstants.assetsCategoriesPath}8.png',
        type: AppConstants.regularCategoryType,
      ),
      
      // Snacks & Drinks Categories
      Category(
        id: 'snacks_1',
        name: 'Chips & Namkeen',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_2',
        name: 'Sweets & Chocolates',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_3',
        name: 'Drinks & Juices',
        image: '${AppConstants.assetsCategoriesPath}3.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_4',
        name: 'Tea, Coffee & Milk Drinks',
        image: '${AppConstants.assetsCategoriesPath}4.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_5',
        name: 'Instant Food',
        image: '${AppConstants.assetsCategoriesPath}5.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_6',
        name: 'Sauces & Spreads',
        image: '${AppConstants.assetsCategoriesPath}6.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_7',
        name: 'Paan Corner',
        image: '${AppConstants.assetsCategoriesPath}7.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: 'snacks_8',
        name: 'Ice Creams & More',
        image: '${AppConstants.assetsCategoriesPath}8.png',
        type: AppConstants.regularCategoryType,
      ),
      
      // Promotional Categories
      Category(
        id: 'promo_1',
        name: 'Ramadan Specials',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.promotionalCategoryType,
        tag: 'Festive Finds',
      ),
      Category(
        id: 'promo_2',
        name: 'XTCY',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.promotionalCategoryType,
        tag: 'Featured',
      ),
      Category(
        id: 'promo_3',
        name: 'Fan Jersey',
        image: '${AppConstants.assetsCategoriesPath}3.png',
        type: AppConstants.promotionalCategoryType,
        tag: 'New Launch',
      ),
      
      // Store Categories
      Category(
        id: 'store_1',
        name: 'Pooja',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_2',
        name: 'Pharma',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_3',
        name: 'Pet',
        image: '${AppConstants.assetsCategoriesPath}3.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_4',
        name: 'Sports',
        image: '${AppConstants.assetsCategoriesPath}4.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_5',
        name: 'Fashion Basics',
        image: '${AppConstants.assetsCategoriesPath}5.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_6',
        name: 'Stationery',
        image: '${AppConstants.assetsCategoriesPath}6.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_7',
        name: 'Book',
        image: '${AppConstants.assetsCategoriesPath}7.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_8',
        name: 'Toy',
        image: '${AppConstants.assetsCategoriesPath}8.png',
        type: AppConstants.storeCategoryType,
      ),
    ];
  }

  List<Product> _getMockFeaturedProducts() {
    return [
      Product(
        id: '1',
        name: 'Fresh Organic Tomatoes',
        image: '${AppConstants.assetsProductsPath}1.png',
        price: 49.0,
        mrp: 60.0,
        inStock: true,
        categoryId: 'grocery_1',
        isFeatured: true,
      ),
      Product(
        id: '2',
        name: 'Premium Basmati Rice 5kg',
        image: '${AppConstants.assetsProductsPath}2.png',
        price: 299.0,
        mrp: 350.0,
        inStock: true,
        categoryId: 'grocery_2',
        isFeatured: true,
      ),
      Product(
        id: '3',
        name: 'Whole Wheat Atta 10kg',
        image: '${AppConstants.assetsProductsPath}3.png',
        price: 450.0,
        mrp: 500.0,
        inStock: true,
        categoryId: 'grocery_2',
        isFeatured: true,
      ),
      Product(
        id: '4',
        name: 'Aashirvaad Atta',
        image: '${AppConstants.assetsProductsPath}4.png',
        price: 350.0,
        mrp: 380.0,
        inStock: true,
        categoryId: 'grocery_2',
        isFeatured: true,
      ),
    ];
  }

  List<Product> _getMockNewArrivals() {
    return [
      Product(
        id: '5',
        name: 'Organic Apples',
        image: '${AppConstants.assetsProductsPath}5.png',
        price: 180.0,
        mrp: 200.0,
        inStock: true,
        categoryId: 'grocery_1',
      ),
      Product(
        id: '6',
        name: 'Fresh Farm Eggs 12pcs',
        image: '${AppConstants.assetsProductsPath}6.png',
        price: 80.0,
        mrp: 90.0,
        inStock: true,
        categoryId: 'grocery_4',
      ),
      Product(
        id: '7',
        name: 'Amul Pure Ghee 1L',
        image: '${AppConstants.assetsProductsPath}1.png',
        price: 580.0,
        mrp: 600.0,
        inStock: true,
        categoryId: 'grocery_3',
      ),
      Product(
        id: '8',
        name: 'Lays Classic Chips',
        image: '${AppConstants.assetsProductsPath}2.png',
        price: 20.0,
        mrp: 25.0,
        inStock: true,
        categoryId: 'snacks_1',
      ),
    ];
  }
  
  Map<String, int> _getMockCartQuantities() {
    // Return empty cart (no mock data) for production
    CartLogger.log('HOME_BLOC', 'Returning empty cart for initialization');
    return {};
  }
  
  // Generate subcategory colors for products
  Map<String, Color> _generateSubcategoryColors() {
    return {
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
  }
}