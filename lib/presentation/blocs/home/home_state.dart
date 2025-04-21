import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/category_group_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final String? errorMessage;
  
  // Banner and category data
  final List<String> tabs;
  final int selectedTabIndex;
  final List<String> banners;
  final List<Category> mainCategories;
  final List<Category> snacksCategories;
  final List<Category> storeCategories;
  final List<Category> featuredPromotions;
  
  // Category group data
  final List<CategoryGroup> categoryGroups;
  
  // Cart data
  final int cartItemCount;
  final double cartTotalAmount;
  final String? cartPreviewImage;
  final Map<String, int> cartQuantities;
  
  // Subcategory colors for product cards
  final Map<String, Color> subcategoryColors;

  const HomeState({
    this.status = HomeStatus.initial,
    this.errorMessage,
    this.tabs = const [],
    this.selectedTabIndex = 0,
    this.banners = const [],
    this.mainCategories = const [],
    this.snacksCategories = const [],
    this.storeCategories = const [],
    this.featuredPromotions = const [],
    this.categoryGroups = const [],
    this.cartItemCount = 0,
    this.cartTotalAmount = 0.0, 
    this.cartPreviewImage,
    this.cartQuantities = const {},
    this.subcategoryColors = const {},
  });

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        tabs,
        selectedTabIndex,
        banners,
        mainCategories,
        snacksCategories,
        storeCategories,
        featuredPromotions,
        categoryGroups,
        cartItemCount,
        cartTotalAmount,
        cartPreviewImage,
        cartQuantities,
        subcategoryColors,
      ];

  HomeState copyWith({
    HomeStatus? status,
    String? errorMessage,
    List<String>? tabs,
    int? selectedTabIndex,
    List<String>? banners,
    List<Category>? mainCategories,
    List<Category>? snacksCategories,
    List<Category>? storeCategories,
    List<Category>? featuredPromotions,
    List<CategoryGroup>? categoryGroups,
    int? cartItemCount,
    double? cartTotalAmount,
    String? cartPreviewImage,
    Map<String, int>? cartQuantities,
    Map<String, Color>? subcategoryColors,
  }) {
    return HomeState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      tabs: tabs ?? this.tabs,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      banners: banners ?? this.banners,
      mainCategories: mainCategories ?? this.mainCategories,
      snacksCategories: snacksCategories ?? this.snacksCategories,
      storeCategories: storeCategories ?? this.storeCategories,
      featuredPromotions: featuredPromotions ?? this.featuredPromotions,
      categoryGroups: categoryGroups ?? this.categoryGroups,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotalAmount: cartTotalAmount ?? this.cartTotalAmount,
      cartPreviewImage: cartPreviewImage ?? this.cartPreviewImage,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      subcategoryColors: subcategoryColors ?? this.subcategoryColors,
    );
  }
}