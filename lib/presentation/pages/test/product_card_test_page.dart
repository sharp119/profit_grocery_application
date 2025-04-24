import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/cards/enhanced_product_card.dart';
import '../../widgets/cards/product_card.dart';

class ProductCardTestPage extends StatefulWidget {
  const ProductCardTestPage({Key? key}) : super(key: key);

  @override
  State<ProductCardTestPage> createState() => _ProductCardTestPageState();
}

class _ProductCardTestPageState extends State<ProductCardTestPage> {
  final Map<String, int> _cartQuantities = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Card Comparison'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Original vs Enhanced'),
            
            Row(
              children: [
                Expanded(
                  child: _buildColumnHeader('Original Design'),
                ),
                Expanded(
                  child: _buildColumnHeader('Enhanced Design'),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Test regular product with no discount
            _buildComparisonRow(
              testProduct: _createTestProduct(
                id: '1',
                name: 'Zucchini Fresh',
                price: 99,
                mrp: 99,
                inStock: true,
                image: 'assets/products/1.png',
                weight: '500g',
              ),
              title: 'Regular Product',
              subtitle: 'No discount, in stock',
            ),
            
            SizedBox(height: 24.h),
            
            // Test product with discount
            _buildComparisonRow(
              testProduct: _createTestProduct(
                id: '2',
                name: 'Pure Desi Ghee',
                price: 549,
                mrp: 649,
                inStock: true,
                image: 'assets/products/2.png',
                weight: '500g',
              ),
              title: 'Discounted Product',
              subtitle: '15% discount, in stock',
            ),
            
            SizedBox(height: 24.h),
            
            // Test product with long name
            _buildComparisonRow(
              testProduct: _createTestProduct(
                id: '3',
                name: 'Organic Long-stemmed Broccoli Premium Quality Fresh',
                price: 120,
                mrp: 150,
                inStock: true,
                image: 'assets/products/3.png',
                weight: '250g',
              ),
              title: 'Long Product Name',
              subtitle: 'Tests name truncation',
            ),
            
            SizedBox(height: 24.h),
            
            // Test out of stock product
            _buildComparisonRow(
              testProduct: _createTestProduct(
                id: '4',
                name: 'Refined Sunflower Oil',
                price: 180,
                mrp: 210,
                inStock: false,
                image: 'assets/products/4.png',
                weight: '1L',
              ),
              title: 'Out of Stock Product',
              subtitle: 'Shows availability status',
            ),
            
            SizedBox(height: 24.h),
            
            // Test product in cart
            _buildComparisonRow(
              testProduct: _createTestProduct(
                id: '5',
                name: 'Multigrain Hot Dog Buns',
                price: 70,
                mrp: 80,
                inStock: true,
                image: 'assets/products/5.png',
                weight: '4 pcs',
              ),
              title: 'Product in Cart',
              subtitle: 'Shows quantity controls',
              initialQuantity: 2,
            ),
            
            SizedBox(height: 40.h),
            
            // Add a clear explanation
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enhanced Design Features:',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem('White background for better visibility'),
                  _buildFeatureItem('Delivery time indication (9 MINS)'),
                  _buildFeatureItem('Separate weight display line'),
                  _buildFeatureItem('Green buttons matching the reference image'),
                  _buildFeatureItem('Better spacing and typography'),
                  _buildFeatureItem('Proper discount badge placement'),
                  _buildFeatureItem('Improved out-of-stock indicator'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required Product testProduct,
    required String title,
    required String subtitle,
    int initialQuantity = 0,
  }) {
    // Set initial quantity
    if (initialQuantity > 0 && !_cartQuantities.containsKey(testProduct.id)) {
      _cartQuantities[testProduct.id] = initialQuantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original card
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.7,
                child: ProductCard.fromEntity(
                  product: testProduct,
                  onTap: () {},
                  onQuantityChanged: (quantity) {
                    setState(() {
                      _cartQuantities[testProduct.id] = quantity;
                    });
                  },
                  quantity: _cartQuantities[testProduct.id] ?? 0,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Enhanced card
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.7,
                child: EnhancedProductCard.fromEntity(
                  product: testProduct,
                  onTap: () {},
                  // onQuantityChanged: (quantity) {
                  //   setState(() {
                  //     _cartQuantities[testProduct.id] = quantity;
                  //   });
                  // },
                  // quantity: _cartQuantities[testProduct.id] ?? 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.accentColor.withOpacity(0.7),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create test products
  Product _createTestProduct({
    required String id,
    required String name,
    required double price,
    required double mrp,
    required bool inStock,
    required String image,
    String? weight,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      mrp: mrp,
      inStock: inStock,
      image: image,
      description: 'Test product description',
      categoryId: 'test_category',
      subcategoryId: 'test_subcategory',
      tags: ['test'],
      weight: weight,
      isActive: true,
      isFeatured: false,
    );
  }
}