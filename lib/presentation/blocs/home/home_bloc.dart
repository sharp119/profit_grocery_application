import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
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
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));

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
    
    // Update cart quantities
    final updatedCartQuantities = Map<String, int>.from(state.cartQuantities);
    
    if (quantity <= 0) {
      updatedCartQuantities.remove(product.id);
    } else {
      updatedCartQuantities[product.id] = quantity;
    }
    
    // Calculate new cart total and count
    final cartItemCount = updatedCartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
    
    // Choose the first product in cart for preview, or null if cart empty
    String? cartPreviewImage;
    if (updatedCartQuantities.isNotEmpty) {
      final previewProductId = updatedCartQuantities.keys.first;
      // In a real app, we'd look up the product image from repository
      cartPreviewImage = '${AppConstants.assetsProductsPath}1.png';
    }
    
    emit(state.copyWith(
      cartQuantities: updatedCartQuantities,
      cartItemCount: cartItemCount,
      cartTotalAmount: cartTotalAmount,
      cartPreviewImage: cartPreviewImage,
    ));
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
      Product(
        id: '11',
        name: 'Maggi Noodles Pack of 12',
        image: '${AppConstants.assetsProductsPath}5.png',
        price: 160.0,
        mrp: 180.0,
        inStock: true,
        categoryId: 'snacks_5',
      ),
      Product(
        id: '12',
        name: 'Surf Excel 1kg',
        image: '${AppConstants.assetsProductsPath}6.png',
        price: 140.0,
        mrp: 150.0,
        inStock: false,
        categoryId: 'kitchen_4',
      ),
    ];
  }
  
  Map<String, int> _getMockCartQuantities() {
    return {
      '1': 2, // 2 items of product with ID '1' in cart
      '3': 1, // 1 item of product with ID '3' in cart
    };
  }
  
  // Get random category groups for home screen
  List<CategoryGroup> _getMockCategoryGroups() {
    // Get 4 random category groups from our pre-defined list
    return CategoryGroups.getRandomGroups(4);
  }
}