import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseDatabase firebaseDatabase;

  CategoryRepositoryImpl({
    required this.firebaseDatabase,
  });

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    bool activeOnly = true,
  }) async {
    try {
      // For now, return mock data
      // In a real implementation, we would fetch from Firebase
      return Right(_getMockCategories());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get categories: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String categoryId) async {
    try {
      final categories = _getMockCategories();
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      );
      return Right(category);
    } catch (e) {
      return Left(NotFoundFailure(message: 'Category not found: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Subcategory>>> getSubcategoriesByCategoryId(
    String categoryId, {
    bool activeOnly = true,
  }) async {
    try {
      final subcategories = _getMockSubcategories()
          .where((s) => s.categoryId == categoryId)
          .toList();
      return Right(subcategories);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get subcategories: $e'));
    }
  }

  @override
  Future<Either<Failure, Subcategory>> getSubcategoryById(
      String subcategoryId) async {
    try {
      final subcategories = _getMockSubcategories();
      final subcategory = subcategories.firstWhere(
        (s) => s.id == subcategoryId,
        orElse: () => throw Exception('Subcategory not found'),
      );
      return Right(subcategory);
    } catch (e) {
      return Left(NotFoundFailure(message: 'Subcategory not found: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getFeaturedCategories() async {
    try {
      final categories = _getMockCategories()
          .where((c) => c.type == AppConstants.promotionalCategoryType)
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get featured categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategoriesByType(
    String type, {
    bool activeOnly = true,
  }) async {
    try {
      final categories = _getMockCategories()
          .where((c) => c.type == type)
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get categories by type: $e'));
    }
  }

  // Mock data methods - in a real app, these would be fetched from Firebase
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
      
      // Store Categories
      Category(
        id: 'store_1',
        name: 'Pooja Store',
        image: '${AppConstants.assetsCategoriesPath}1.png',
        type: AppConstants.storeCategoryType,
      ),
      Category(
        id: 'store_2',
        name: 'Pharma Store',
        image: '${AppConstants.assetsCategoriesPath}2.png',
        type: AppConstants.storeCategoryType,
      ),
    ];
  }

  List<Subcategory> _getMockSubcategories() {
    return [
      Subcategory(
        id: 'sub_1',
        name: 'Fresh Vegetables',
        image: '${AppConstants.assetsSubcategoriesPath}1.png',
        categoryId: 'grocery_1',
      ),
      Subcategory(
        id: 'sub_2',
        name: 'Fresh Fruits',
        image: '${AppConstants.assetsSubcategoriesPath}2.png',
        categoryId: 'grocery_1',
      ),
      Subcategory(
        id: 'sub_3',
        name: 'Wheat Flour',
        image: '${AppConstants.assetsSubcategoriesPath}3.png',
        categoryId: 'grocery_2',
      ),
      Subcategory(
        id: 'sub_4',
        name: 'Rice',
        image: '${AppConstants.assetsSubcategoriesPath}4.png',
        categoryId: 'grocery_2',
      ),
    ];
  }
}
