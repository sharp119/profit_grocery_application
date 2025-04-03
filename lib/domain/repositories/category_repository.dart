import 'package:dartz/dartz.dart';

import '../entities/category.dart';
import '../../core/errors/failures.dart';

abstract class CategoryRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories({
    bool activeOnly = true,
  });
  
  /// Get a single category by ID
  Future<Either<Failure, Category>> getCategoryById(String categoryId);
  
  /// Get subcategories for a specific category
  Future<Either<Failure, List<Subcategory>>> getSubcategoriesByCategoryId(
    String categoryId, {
    bool activeOnly = true,
  });
  
  /// Get a single subcategory by ID
  Future<Either<Failure, Subcategory>> getSubcategoryById(String subcategoryId);
  
  /// Get featured categories
  Future<Either<Failure, List<Category>>> getFeaturedCategories();
  
  /// Get categories by type (regular, store, promotional)
  Future<Either<Failure, List<Category>>> getCategoriesByType(
    String type, {
    bool activeOnly = true,
  });
}