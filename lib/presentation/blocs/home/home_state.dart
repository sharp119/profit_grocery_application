import 'package:equatable/equatable.dart';

import '../../../data/models/category_group_model.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  error,
}

class HomeState extends Equatable {
  final HomeStatus status;
  final int selectedTabIndex;
  final List<String> tabs;
  final List<String> banners;
  final List<Category> categories;
  final List<Category> mainCategories;
  final List<Category> snacksCategories;
  final List<Category> beautyCategories;
  final List<Category> storeCategories;
  final List<CategoryGroup> categoryGroups;
  final List<Category> featuredPromotions;
  final List<Product> featuredProducts;
  final List<Product> newArrivals;
  final List<Product> bestSellers;
  final String? errorMessage;
  final int cartItemCount;
  final String? cartPreviewImage;
  final double? cartTotalAmount;
  final Map<String, int> cartQuantities;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedTabIndex = 0,
    this.tabs = const [],
    this.banners = const [],
    this.categories = const [],
    this.mainCategories = const [],
    this.snacksCategories = const [],
    this.beautyCategories = const [],
    this.storeCategories = const [],
    this.categoryGroups = const [],
    this.featuredPromotions = const [],
    this.featuredProducts = const [],
    this.newArrivals = const [],
    this.bestSellers = const [],
    this.errorMessage,
    this.cartItemCount = 0,
    this.cartPreviewImage,
    this.cartTotalAmount,
    this.cartQuantities = const {},
  });

  HomeState copyWith({
    HomeStatus? status,
    int? selectedTabIndex,
    List<String>? tabs,
    List<String>? banners,
    List<Category>? categories,
    List<Category>? mainCategories,
    List<Category>? snacksCategories,
    List<Category>? beautyCategories,
    List<Category>? storeCategories,
    List<CategoryGroup>? categoryGroups,
    List<Category>? featuredPromotions,
    List<Product>? featuredProducts,
    List<Product>? newArrivals,
    List<Product>? bestSellers,
    String? errorMessage,
    int? cartItemCount,
    String? cartPreviewImage,
    double? cartTotalAmount,
    Map<String, int>? cartQuantities,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      tabs: tabs ?? this.tabs,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      mainCategories: mainCategories ?? this.mainCategories,
      snacksCategories: snacksCategories ?? this.snacksCategories,
      beautyCategories: beautyCategories ?? this.beautyCategories,
      storeCategories: storeCategories ?? this.storeCategories,
      categoryGroups: categoryGroups ?? this.categoryGroups,
      featuredPromotions: featuredPromotions ?? this.featuredPromotions,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      bestSellers: bestSellers ?? this.bestSellers,
      errorMessage: errorMessage ?? this.errorMessage,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartPreviewImage: cartPreviewImage ?? this.cartPreviewImage,
      cartTotalAmount: cartTotalAmount ?? this.cartTotalAmount,
      cartQuantities: cartQuantities ?? this.cartQuantities,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedTabIndex,
    tabs,
    banners,
    categories,
    mainCategories,
    snacksCategories,
    beautyCategories,
    storeCategories,
    categoryGroups,
    featuredPromotions,
    featuredProducts,
    newArrivals,
    bestSellers,
    errorMessage,
    cartItemCount,
    cartPreviewImage,
    cartTotalAmount,
    cartQuantities,
  ];
}