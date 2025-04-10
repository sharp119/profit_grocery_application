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

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // In a real app, we would inject repository dependencies here
  // final CategoryRepository _categoryRepository;
  // final ProductRepository _productRepository;
  // final CartRepository _cartRepository;

  HomeBloc() : super(const HomeState()) {
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
      final beautyCategories = allCategories.where((c) => 
          c.id.startsWith('beauty_')).toList();
      final storeCategories = allCategories.where((c) => 
          c.type == AppConstants.storeCategoryType).toList();
      final featuredPromotions = allCategories.where((c) => 
          c.type == AppConstants.promotionalCategoryType).toList();
          
      // Get products
      final featuredProducts = _getMockFeaturedProducts();
      final newArrivals = _getMockNewArrivals();
      final bestSellers = _getMockBestSellers();
      
      // Get cart data
      final cartQuantities = _getMockCartQuantities();
      final cartItemCount = cartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
      const cartPreviewImage = '${AppConstants.assetsProductsPath}1.png'; // First product in cart
      final cartTotalAmount = _calculateCartTotal(cartQuantities);

      // Get category groups for 4x2 grid widget
      final categoryGroups = _getMockCategoryGroups();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        status: HomeStatus.loaded,
        tabs: tabs,
        banners: banners,
        categories: allCategories,
        mainCategories: mainCategories,
        snacksCategories: snacksCategories,
        beautyCategories: beautyCategories,
        storeCategories: storeCategories,
        featuredPromotions: featuredPromotions,
        featuredProducts: featuredProducts,
        newArrivals: newArrivals,
        bestSellers: bestSellers,
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
      // Keep current data while refreshing
      emit(state.copyWith(status: HomeStatus.loading));

      // Simulate fetch of fresh data
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, we'd get fresh data from repositories
      // Reuse the load data logic for our demo
      add(const LoadHomeData());
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

  List<Product> _getMockBestSellers() {
    // Get bestseller products from the inventory using IDs from BestsellerProducts
    final allProducts = ProductInventory.getAllProducts();
    final bestSellerProducts = <Product>[];
    
    // Find each bestseller product by ID
    for (final productId in BestsellerProducts.productIds) {
      // Look for the product in the inventory
      final product = allProducts.firstWhere(
        (product) => product.id == productId,
        orElse: () => ProductModel(
          id: 'fallback_${productId}',
          name: 'Product Not Found',
          image: '${AppConstants.assetsProductsPath}1.png',
          price: 0.0,
          categoryId: 'fallback',
        ),
      );
      
      // Add to list if found
      if (product != null) {
        bestSellerProducts.add(product);
      }
    }
    
    // If no products found (unlikely), return a fallback list
    if (bestSellerProducts.isEmpty) {
      return [
        Product(
          id: '9',
          name: 'Tata Salt 1kg',
          image: '${AppConstants.assetsProductsPath}3.png',
          price: 22.0,
          mrp: 24.0,
          inStock: true,
          categoryId: 'grocery_3',
        ),
        Product(
          id: '10',
          name: 'Good Day Cookies',
          image: '${AppConstants.assetsProductsPath}4.png',
          price: 30.0,
          mrp: 35.0,
          inStock: true,
          categoryId: 'kitchen_1',
        ),
      ];
    }
    
    return bestSellerProducts;
  }
  
  Map<String, int> _getMockCartQuantities() {
    // Return empty cart (no mock data) for production
    CartLogger.log('HOME_BLOC', 'Returning empty cart for initialization');
    return {};
  }
  
  // Get random category groups for home screen
  List<CategoryGroup> _getMockCategoryGroups() {
    // Get 4 random category groups from our pre-defined list
    return CategoryGroups.getRandomGroups(4);
  }
  
  // Generate subcategory colors for products
  Map<String, Color> _generateSubcategoryColors() {
    final Map<String, Color> colors = {};
    
    // Category ID-based colors
    // Main categories
    colors['grocery_1'] = const Color(0xFF1A5D1A); // Dark green for vegetables
    colors['grocery_2'] = const Color(0xFFD5A021); // Gold/yellow for grains
    colors['grocery_3'] = const Color(0xFFFF6B6B); // Soft red for oils/spices
    colors['grocery_4'] = const Color(0xFFE5BEEC); // Light lavender for dairy
    
    // Kitchen categories
    colors['kitchen_1'] = const Color(0xFFA9907E); // Brown for bakery
    colors['kitchen_2'] = const Color(0xFFABC4AA); // Sage green for dry fruits
    colors['kitchen_3'] = const Color(0xFF675D50); // Dark brown for meat
    colors['kitchen_4'] = const Color(0xFF3F4E4F); // Dark slate for kitchenware
    
    // Snacks categories
    colors['snacks_1'] = const Color(0xFFECB159); // Yellow/orange for chips
    colors['snacks_2'] = const Color(0xFFBF3131); // Dark red for sweets
    colors['snacks_3'] = const Color(0xFF219C90); // Teal for drinks
    colors['snacks_4'] = const Color(0xFF6C3428); // Coffee brown
    colors['snacks_5'] = const Color(0xFFEEBB4D); // Amber for instant food
    colors['snacks_6'] = const Color(0xFF9A3B3B); // Burgundy for sauces
    colors['snacks_7'] = const Color(0xFF116A7B); // Teal for paan
    colors['snacks_8'] = const Color(0xFFCDDBD5); // Light mint for ice cream
    
    // Store categories
    colors['store_1'] = const Color(0xFFE55604); // Orange for pooja
    colors['store_2'] = const Color(0xFF557A46); // Green for pharma
    colors['store_3'] = const Color(0xFF8ECDDD); // Light blue for pet
    colors['store_4'] = const Color(0xFF068DA9); // Blue for sports
    colors['store_5'] = const Color(0xFF9E4784); // Purple for fashion
    colors['store_6'] = const Color(0xFF512B81); // Deep purple for stationery
    colors['store_7'] = const Color(0xFF86A3B8); // Slate blue for books
    colors['store_8'] = const Color(0xFFEF9A53); // Orange for toys

    // Color mappings for mock product category IDs
    colors['1'] = const Color(0xFF1A5D1A);  // Green for product ID 1
    colors['2'] = const Color(0xFFE5BEEC);  // Light purple for product ID 2
    colors['3'] = const Color(0xFFECB159);  // Yellow for product ID 3
    colors['4'] = const Color(0xFF219C90);  // Teal for product ID 4
    colors['5'] = const Color(0xFF9A3B3B);  // Burgundy for product ID 5
    colors['6'] = const Color(0xFF557A46);  // Green for product ID 6
    colors['7'] = const Color(0xFF8ECDDD);  // Light blue for product ID 7
    colors['8'] = const Color(0xFF068DA9);  // Blue for product ID 8
    colors['9'] = const Color(0xFF675D50);  // Dark brown for product ID 9
    colors['10'] = const Color(0xFFA9907E); // Brown for product ID 10
    colors['11'] = const Color(0xFFECB159); // Yellow for product ID 11
    colors['12'] = const Color(0xFF3F4E4F); // Slate for product ID 12

    // Add explicit category mapping for bestsellers
    colors['category_1'] = const Color(0xFF1A5D1A); // Dark green
    colors['category_2'] = const Color(0xFFE5BEEC); // Light lavender 
    colors['category_3'] = const Color(0xFFECB159); // Yellow/orange
    colors['category_4'] = const Color(0xFF219C90); // Teal
    
    // Add mappings for CategoryProductsBloc categories
    colors['vegetables'] = const Color(0xFF1A5D1A);    // Dark green
    colors['dairy'] = const Color(0xFFE5BEEC);         // Light lavender
    colors['snacks'] = const Color(0xFFECB159);        // Yellow/orange
    colors['beverages'] = const Color(0xFF219C90);     // Teal
    colors['grocery'] = const Color(0xFFD5A021);       // Gold/yellow
    colors['household'] = const Color(0xFF3F4E4F);     // Dark slate
    colors['personal_care'] = const Color(0xFF9E4784); // Purple 
    colors['baby_care'] = const Color(0xFF8ECDDD);     // Light blue
    
    return colors;
  }
}