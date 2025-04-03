import 'package:equatable/equatable.dart';

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
  final List<Product> featuredProducts;
  final List<Product> newArrivals;
  final List<Product> bestSellers;
  final String? errorMessage;
  final int cartItemCount;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedTabIndex = 0,
    this.tabs = const [],
    this.banners = const [],
    this.categories = const [],
    this.featuredProducts = const [],
    this.newArrivals = const [],
    this.bestSellers = const [],
    this.errorMessage,
    this.cartItemCount = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    int? selectedTabIndex,
    List<String>? tabs,
    List<String>? banners,
    List<Category>? categories,
    List<Product>? featuredProducts,
    List<Product>? newArrivals,
    List<Product>? bestSellers,
    String? errorMessage,
    int? cartItemCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      tabs: tabs ?? this.tabs,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      newArrivals: newArrivals ?? this.newArrivals,
      bestSellers: bestSellers ?? this.bestSellers,
      errorMessage: errorMessage ?? this.errorMessage,
      cartItemCount: cartItemCount ?? this.cartItemCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedTabIndex,
    tabs,
    banners,
    categories,
    featuredProducts,
    newArrivals,
    bestSellers,
    errorMessage,
    cartItemCount,
  ];
}
