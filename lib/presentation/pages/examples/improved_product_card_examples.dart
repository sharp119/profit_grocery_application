import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/cards/improved_product_card.dart';
import '../../widgets/grids/horizontal_bestseller_grid.dart';
import '../../../core/constants/app_theme.dart';

/**
 * ImprovedProductCardExamples
 * 
 * This file demonstrates various use cases for the ImprovedProductCard and 
 * HorizontalBestsellerGrid components to show their flexibility and capabilities.
 * 
 * Use Cases Covered:
 * 1. Basic product card with Product object
 * 2. Product card using only productId (auto-resolution)
 * 3. Fixed width cards for horizontal scrolling
 * 4. Custom pricing and discount overrides
 * 5. Horizontal bestseller grid implementation
 * 6. Different configuration options
 * 
 * This serves as both documentation and testing examples for the components.
 */

class ImprovedProductCardExamples extends StatefulWidget {
  const ImprovedProductCardExamples({Key? key}) : super(key: key);

  @override
  State<ImprovedProductCardExamples> createState() => _ImprovedProductCardExamplesState();
}

class _ImprovedProductCardExamplesState extends State<ImprovedProductCardExamples> {
  // Sample cart quantities for demonstration
  final Map<String, int> _cartQuantities = {
    'product_1': 2,
    'product_2': 1,
    'product_3': 0,
  };

  // Sample product for demonstration
  late Product _sampleProduct;

  @override
  void initState() {
    super.initState();
    _sampleProduct = Product(
      id: 'sample_product_1',
      name: 'Organic Basmati Rice Premium Quality Long Grain',
      image: 'https://example.com/rice.jpg',
      description: 'Premium quality organic basmati rice',
      price: 299.0,
      mrp: 399.0,
      inStock: true,
      categoryId: 'grocery',
      subcategoryId: 'rice',
      tags: ['organic', 'basmati', 'premium'],
      isFeatured: true,
      isActive: true,
      brand: 'Organic Valley',
      weight: '1 kg',
      categoryName: 'grocery',
    );
  }

  void _handleProductTap(Product product) {
    print('Tapped on product: ${product.name}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on ${product.name}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleQuantityChanged(Product product, int quantity) {
    setState(() {
      _cartQuantities[product.id] = quantity;
    });
    
    print('Quantity changed for ${product.name}: $quantity');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} quantity: $quantity'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Improved Product Card Examples'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Basic Product Card
            _buildSectionTitle('1. Basic Product Card'),
            _buildDescription(
              'Standard product card with Product object, showing all features including '
              'savings indicator, brand/weight, and add to cart functionality.'
            ),
            Container(
              width: 180.w,
              child: ImprovedProductCard(
                product: _sampleProduct,
                onTap: () => _handleProductTap(_sampleProduct),
                onQuantityChanged: _handleQuantityChanged,
                quantity: _cartQuantities[_sampleProduct.id] ?? 0,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Example 2: Loading Product Card
            _buildSectionTitle('2. Loading Product Card'),
            _buildDescription(
              'Product card in loading state using the convenient loading constructor. '
              'Shows shimmer animation without attempting to resolve any product data.'
            ),
            Container(
              width: 180.w,
              child: ImprovedProductCard.loading(
                width: 180.w,
                height: 280.h,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Example 3: Product Card with Product ID only
            _buildSectionTitle('3. Product Card with Product ID'),
            _buildDescription(
              'Product card using only productId. The card will automatically resolve '
              'the product details and display them. Shows loading state during resolution.'
            ),
            Container(
              width: 180.w,
              child: ImprovedProductCard(
                productId: 'some_real_product_id', // Replace with actual product ID
                onTap: () => print('Tapped product resolved from ID'),
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Example 4: Custom Pricing Override
            _buildSectionTitle('4. Custom Pricing Override'),
            _buildDescription(
              'Product card with custom pricing and discount information. Useful for '
              'special promotions, bestseller pricing, or dynamic pricing scenarios.'
            ),
            Container(
              width: 180.w,
              child: ImprovedProductCard(
                product: _sampleProduct,
                finalPrice: 249.0, // Override final price
                originalPrice: 399.0, // Override original price
                hasDiscount: true,
                discountType: 'flat',
                discountValue: 150.0,
                onTap: () => _handleProductTap(_sampleProduct),
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Example 5: Horizontal Scrolling Grid
            _buildSectionTitle('5. Horizontal Product Grid'),
            _buildDescription(
              'Multiple cards in a horizontal scrolling layout. Fixed width cards allow '
              'consistent spacing and show 2 full cards + part of 3rd for scroll indication.'
            ),
            SizedBox(
              height: 300.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // Show 5 sample cards
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemBuilder: (context, index) {
                  return Container(
                    width: 180.w,
                    margin: EdgeInsets.only(right: 16.w),
                    child: ImprovedProductCard(
                      product: Product(
                        id: 'demo_product_$index',
                        name: 'Demo Product ${index + 1} with Long Name for Testing',
                        image: 'https://picsum.photos/200/200?random=$index',
                        description: 'Demo product for testing',
                        price: 199.0 + (index * 50),
                        mrp: 299.0 + (index * 50),
                        inStock: index != 2, // Make one out of stock for demo
                        categoryId: 'demo',
                        subcategoryId: 'test',
                        tags: ['demo'],
                        isFeatured: index % 2 == 0,
                        isActive: true,
                        brand: 'Demo Brand',
                        weight: '${index + 1}00g',
                      ),
                      onTap: () => print('Tapped demo product $index'),
                      onQuantityChanged: (product, qty) => print('Demo product $index quantity: $qty'),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Example 6: Horizontal Bestseller Grid Component
            _buildSectionTitle('6. Horizontal Bestseller Grid'),
            _buildDescription(
              'Complete bestseller section with horizontal scrolling, real-time updates, '
              'and dynamic loading. This is the recommended component for home screen bestsellers.'
            ),
            HorizontalBestsellerSection(
              title: 'Sample Bestsellers',
              viewAllText: 'View All',
              onViewAllTap: () => print('View all bestsellers tapped'),
              onProductTap: _handleProductTap,
              onQuantityChanged: _handleQuantityChanged,
              cartQuantities: _cartQuantities,
              limit: 8,
              ranked: false,
              useRealTimeUpdates: false, // Disable for demo
              showBestsellerBadge: true,
            ),
            
            SizedBox(height: 32.h),
            
            // Example 7: Configuration Options
            _buildSectionTitle('7. Configuration Options'),
            _buildDescription(
              'Different configuration options available for the product cards.'
            ),
            
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                // Without brand/weight
                Container(
                  width: 160.w,
                  child: Column(
                    children: [
                      Text('No Brand/Weight', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      ImprovedProductCard(
                        product: _sampleProduct,
                        width: 160.w,
                        height: 240.h,
                        showBrand: false,
                        showWeight: false,
                        onTap: () => print('No brand/weight card'),
                      ),
                    ],
                  ),
                ),
                
                // Without savings indicator
                Container(
                  width: 160.w,
                  child: Column(
                    children: [
                      Text('No Savings Badge', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      ImprovedProductCard(
                        product: _sampleProduct,
                        width: 160.w,
                        height: 240.h,
                        showSavingsIndicator: false,
                        onTap: () => print('No savings badge card'),
                      ),
                    ],
                  ),
                ),
                
                // Without quantity controls
                Container(
                  width: 160.w,
                  child: Column(
                    children: [
                      Text('No Quantity Controls', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      ImprovedProductCard(
                        product: _sampleProduct,
                        width: 160.w,
                        height: 240.h,
                        enableQuantityControls: false,
                        onTap: () => print('No quantity controls card'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32.h),
            
            // Usage Instructions
            _buildSectionTitle('Usage Instructions'),
            _buildUsageInstructions(),
            
            SizedBox(height: 100.h), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.white70,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildUsageInstructions() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Implementation Guide:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: 12.h),
          
          _buildInstructionItem(
            '1. Basic Usage',
            'Use ImprovedProductCard with either a Product object or productId string. '
            'The card will handle product resolution automatically.',
          ),
          
          _buildInstructionItem(
            '2. Horizontal Scrolling',
            'For horizontal grids, use fixed width (180.w recommended) and set up '
            'ListView.builder with horizontal scrollDirection.',
          ),
          
          _buildInstructionItem(
            '3. Bestsellers Section',
            'Use HorizontalBestsellerSection for a complete bestseller implementation '
            'with section header and horizontal scrolling grid.',
          ),
          
          _buildInstructionItem(
            '4. Callbacks',
            'Implement onTap for navigation and onQuantityChanged for cart updates. '
            'Pass current cart quantities for proper state management.',
          ),
          
          _buildInstructionItem(
            '5. Customization',
            'Override pricing, discounts, and visual options using the available '
            'parameters. Disable features using boolean flags.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
