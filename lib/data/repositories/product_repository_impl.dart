import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseDatabase firebaseDatabase;

  ProductRepositoryImpl({
    required this.firebaseDatabase,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    bool activeOnly = true,
  }) async {
    try {
      // For now, return mock data
      // In a real implementation, we would fetch from Firebase
      return Right(_getMockProducts());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products: $e'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String productId) async {
    try {
      final products = _getMockProducts();
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      return Right(product);
    } catch (e) {
      return Left(NotFoundFailure(message: 'Product not found: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId, {
    bool activeOnly = true,
  }) async {
    try {
      final products = _getMockProducts()
          .where((p) => p.categoryId == categoryId)
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products by category: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsBySubcategory(
    String subcategoryId, {
    bool activeOnly = true,
  }) async {
    try {
      final products = _getMockProducts()
          .where((p) => p.subcategoryId == subcategoryId)
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products by subcategory: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts() async {
    try {
      final products = _getMockProducts()
          .where((p) => p.isFeatured)
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get featured products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getBestSellerProducts() async {
    try {
      // In a real app, we would fetch bestsellers based on sales data
      // For now, return first 4 products as bestsellers
      final products = _getMockProducts().take(4).toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get bestseller products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String keyword, {
    bool activeOnly = true,
  }) async {
    try {
      final products = _getMockProducts()
          .where((p) => 
              p.name.toLowerCase().contains(keyword.toLowerCase()) || 
              (p.description != null && 
               p.description!.toLowerCase().contains(keyword.toLowerCase())))
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search products: $e'));
    }
  }

  // Mock data methods - in a real app, these would be fetched from Firebase
  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Fresh Organic Tomatoes',
        image: '${AppConstants.assetsProductsPath}1.png',
        description: 'Fresh organic tomatoes grown in local farms.',
        price: 49.0,
        mrp: 60.0,
        inStock: true,
        categoryId: 'grocery_1',
        subcategoryId: 'sub_1',
        isFeatured: true,
      ),
      Product(
        id: '2',
        name: 'Premium Basmati Rice 5kg',
        image: '${AppConstants.assetsProductsPath}2.png',
        description: 'Premium quality aged basmati rice.',
        price: 299.0,
        mrp: 350.0,
        inStock: true,
        categoryId: 'grocery_2',
        subcategoryId: 'sub_4',
        isFeatured: true,
      ),
      Product(
        id: '3',
        name: 'Whole Wheat Atta 10kg',
        image: '${AppConstants.assetsProductsPath}3.png',
        description: '100% whole wheat flour for chapatis and bread.',
        price: 450.0,
        mrp: 500.0,
        inStock: true,
        categoryId: 'grocery_2',
        subcategoryId: 'sub_3',
        isFeatured: true,
      ),
      Product(
        id: '4',
        name: 'Fresh Apples',
        image: '${AppConstants.assetsProductsPath}4.png',
        description: 'Fresh and juicy apples imported from Kashmir.',
        price: 180.0,
        mrp: 200.0,
        inStock: true,
        categoryId: 'grocery_1',
        subcategoryId: 'sub_2',
      ),
      Product(
        id: '5',
        name: 'Organic Carrots 500g',
        image: '${AppConstants.assetsProductsPath}5.png',
        description: 'Organic carrots freshly harvested.',
        price: 60.0,
        mrp: 70.0,
        inStock: true,
        categoryId: 'grocery_1',
        subcategoryId: 'sub_1',
      ),
      Product(
        id: '6',
        name: 'Lays Classic Chips',
        image: '${AppConstants.assetsProductsPath}6.png',
        description: 'Classic salted potato chips.',
        price: 20.0,
        mrp: 25.0,
        inStock: true,
        categoryId: 'snacks_1',
      ),
      Product(
        id: '7',
        name: 'Amul Butter 500g',
        image: '${AppConstants.assetsProductsPath}1.png',
        description: 'Pure dairy butter from Amul.',
        price: 240.0,
        mrp: 250.0,
        inStock: true,
        categoryId: 'grocery_4',
      ),
      Product(
        id: '8',
        name: 'Tata Salt 1kg',
        image: '${AppConstants.assetsProductsPath}2.png',
        description: 'Iodized salt for cooking.',
        price: 22.0,
        mrp: 24.0,
        inStock: true,
        categoryId: 'grocery_3',
      ),
    ];
  }
}
