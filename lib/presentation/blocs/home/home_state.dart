import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/firestore/category_group_firestore_model.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  error,
}

class HomeState extends Equatable {
  final HomeStatus status;
  final List<String> banners;
  final List<Category> mainCategories;
  final List<Category> snacksCategories;
  final List<Category> storeCategories;
  final List<Category> featuredPromotions;
  final List<Product> bestSellers;
  final Map<String, int> cartQuantities;
  final Map<String, Color> subcategoryColors;
  final int cartItemCount;
  final double cartTotalAmount;
  final String? errorMessage;
  final List<String> tabs;
  final int selectedTabIndex;
  final List<CategoryGroupFirestore> categoryGroups;

  const HomeState({
    this.status = HomeStatus.initial,
    this.banners = const [],
    this.mainCategories = const [],
    this.snacksCategories = const [],
    this.storeCategories = const [],
    this.featuredPromotions = const [],
    this.bestSellers = const [],
    this.cartQuantities = const {},
    this.subcategoryColors = const {},
    this.cartItemCount = 0,
    this.cartTotalAmount = 0.0,
    this.errorMessage,
    this.tabs = const ['All', 'Electronics', 'Beauty', 'Kids', 'Gifting'],
    this.selectedTabIndex = 0,
    this.categoryGroups = const [],
  });

  HomeState copyWith({
    HomeStatus? status,
    List<String>? banners,
    List<Category>? mainCategories,
    List<Category>? snacksCategories,
    List<Category>? storeCategories,
    List<Category>? featuredPromotions,
    List<Product>? bestSellers,
    Map<String, int>? cartQuantities,
    Map<String, Color>? subcategoryColors,
    int? cartItemCount,
    double? cartTotalAmount,
    String? errorMessage,
    List<String>? tabs,
    int? selectedTabIndex,
    List<CategoryGroupFirestore>? categoryGroups,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      mainCategories: mainCategories ?? this.mainCategories,
      snacksCategories: snacksCategories ?? this.snacksCategories,
      storeCategories: storeCategories ?? this.storeCategories,
      featuredPromotions: featuredPromotions ?? this.featuredPromotions,
      bestSellers: bestSellers ?? this.bestSellers,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      subcategoryColors: subcategoryColors ?? this.subcategoryColors,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotalAmount: cartTotalAmount ?? this.cartTotalAmount,
      errorMessage: errorMessage ?? this.errorMessage,
      tabs: tabs ?? this.tabs,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      categoryGroups: categoryGroups ?? this.categoryGroups,
    );
  }

  @override
  List<Object?> get props => [
    status,
    banners,
    mainCategories,
    snacksCategories,
    storeCategories,
    featuredPromotions,
    bestSellers,
    cartQuantities,
    subcategoryColors,
    cartItemCount,
    cartTotalAmount,
    errorMessage,
    tabs,
    selectedTabIndex,
    categoryGroups,
  ];
}