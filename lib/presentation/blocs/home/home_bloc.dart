import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
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
      final categories = _getMockCategories();
      final featuredProducts = _getMockFeaturedProducts();
      final newArrivals = _getMockNewArrivals();
      final bestSellers = _getMockBestSellers();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        status: HomeStatus.loaded,
        tabs: tabs,
        banners: banners,
        categories: categories,
        featuredProducts: featuredProducts,
        newArrivals: newArrivals,
        bestSellers: bestSellers,
        cartItemCount: 3, // Mock cart count
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

      // In a real app, we would fetch fresh data from repositories
      // For now, we'll reuse the mock data
      final tabs = _getMockTabs();
      final banners = _getMockBanners();
      final categories = _getMockCategories();
      final featuredProducts = _getMockFeaturedProducts();
      final newArrivals = _getMockNewArrivals();
      final bestSellers = _getMockBestSellers();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        status: HomeStatus.loaded,
        tabs: tabs,
        banners: banners,
        categories: categories,
        featuredProducts: featuredProducts,
        newArrivals: newArrivals,
        bestSellers: bestSellers,
        cartItemCount: 3, // Mock cart count
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
      Category(
        id: '1',
        name: 'Vegetables & Fruits',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: '2',
        name: 'Atta, Rice & Dal',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: '3',
        name: 'Chips & Namkeen',
        image: '${AppConstants.assetsCategoriesPath}3.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: '4',
        name: 'Bakery & Biscuits',
        image: '${AppConstants.assetsCategoriesPath}4.png',
        type: AppConstants.regularCategoryType,
      ),
      Category(
        id: '5',
        name: 'Ramadan Specials',
        image: '${AppConstants.assetsCategoriesPath}5.png',
        type: AppConstants.promotionalCategoryType,
        tag: 'Featured',
      ),
      Category(
        id: '6',
        name: 'Pet Store',
        image: '${AppConstants.assetsCategoriesPath}6.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: '7',
        name: 'Pooja Store',
        image: '${AppConstants.assetsCategoriesPath}7.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: '8',
        name: 'Pharma Store',
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
        categoryId: '1',
        isFeatured: true,
      ),
      Product(
        id: '2',
        name: 'Premium Basmati Rice 5kg',
        image: '${AppConstants.assetsProductsPath}2.png',
        price: 299.0,
        mrp: 350.0,
        inStock: true,
        categoryId: '2',
        isFeatured: true,
      ),
      Product(
        id: '3',
        name: 'Whole Wheat Atta 10kg',
        image: '${AppConstants.assetsProductsPath}3.png',
        price: 450.0,
        mrp: 500.0,
        inStock: true,
        categoryId: '2',
        isFeatured: true,
      ),
      Product(
        id: '4',
        name: 'Aashirvaad Atta',
        image: '${AppConstants.assetsProductsPath}4.png',
        price: 350.0,
        mrp: 380.0,
        inStock: true,
        categoryId: '2',
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
        categoryId: '1',
      ),
      Product(
        id: '6',
        name: 'Fresh Farm Eggs 12pcs',
        image: '${AppConstants.assetsProductsPath}6.png',
        price: 80.0,
        mrp: 90.0,
        inStock: true,
        categoryId: '1',
      ),
      Product(
        id: '7',
        name: 'Amul Pure Ghee 1L',
        image: '${AppConstants.assetsProductsPath}1.png',
        price: 580.0,
        mrp: 600.0,
        inStock: true,
        categoryId: '2',
      ),
      Product(
        id: '8',
        name: 'Lays Classic Chips',
        image: '${AppConstants.assetsProductsPath}2.png',
        price: 20.0,
        mrp: 25.0,
        inStock: true,
        categoryId: '3',
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
        categoryId: '2',
      ),
      Product(
        id: '10',
        name: 'Good Day Cookies',
        image: '${AppConstants.assetsProductsPath}4.png',
        price: 30.0,
        mrp: 35.0,
        inStock: true,
        categoryId: '4',
      ),
      Product(
        id: '11',
        name: 'Maggi Noodles Pack of 12',
        image: '${AppConstants.assetsProductsPath}5.png',
        price: 160.0,
        mrp: 180.0,
        inStock: true,
        categoryId: '2',
      ),
      Product(
        id: '12',
        name: 'Surf Excel 1kg',
        image: '${AppConstants.assetsProductsPath}6.png',
        price: 140.0,
        mrp: 150.0,
        inStock: false,
        categoryId: '4',
      ),
    ];
  }
}
