import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/domain/entities/bestseller_item.dart';
import 'package:profit_grocery_application/domain/entities/bestseller_product.dart';
import 'package:profit_grocery_application/domain/entities/product.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/bestseller_product_card.dart';
import 'package:profit_grocery_application/presentation/widgets/section_header.dart';
import 'package:profit_grocery_application/services/logging_service.dart';
import 'package:profit_grocery_application/presentation/widgets/grids/simple_bestseller_grid.dart';

class BestsellerExamplePage extends StatefulWidget {
  const BestsellerExamplePage({Key? key}) : super(key: key);

  @override
  State<BestsellerExamplePage> createState() => _BestsellerExamplePageState();
}

class _BestsellerExamplePageState extends State<BestsellerExamplePage> {
  final Map<String, int> _cartQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Bestseller Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            
            // Regular Bestseller Grid - Shows multiple bestseller products
            SectionHeader(
              title: 'Bestsellers',
              viewAllText: 'View All',
              onViewAllTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View all bestsellers tapped')),
                );
              },
            ),
            
            // Using the updated SimpleBestsellerGrid with enhanced bestseller discounts
            SimpleBestsellerGrid(
              onProductTap: _onProductTap,
              onQuantityChanged: _onProductQuantityChanged,
              cartQuantities: _cartQuantities,
              limit: 6,  // Show 6 bestsellers
              ranked: true,  // Sort by rank
              crossAxisCount: 2,  // 2 products per row
              showBestsellerBadge: true,  // Show the bestseller badge
            ),
            
            SizedBox(height: 24.h),
            
            // Example section showing how to manually create a BestsellerProduct
            // Use title parameter for title only, and add subtitle as a separate widget
            SectionHeader(
              title: 'Custom Bestseller Example',
            ),
            
            // Add subtitle as a separate text widget
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Creating BestsellerProduct manually',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16.r),
              child: _buildCustomBestsellerExample(),
            ),
            
            SizedBox(height: 24.h),
            
            // Explanation section
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Bestseller Discounts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Bestseller products can have their own special discounts that are different from regular product discounts. These discounts can be either percentage-based or flat amount discounts.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  Text(
                    'Discount Types:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildDiscountTypeExample(
                    'Percentage',
                    'Takes X% off the regular price',
                    '10% off ₹100 = ₹90',
                    Colors.green,
                  ),
                  SizedBox(height: 8.h),
                  _buildDiscountTypeExample(
                    'Flat',
                    'Takes a fixed amount off the regular price',
                    '₹20 off ₹100 = ₹80',
                    Colors.blue,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBestsellerExample() {
    // Create a sample product
    final product = Product(
      id: 'custom-product-1',
      name: 'Premium Chocolate Cookies',
      description: 'Delicious chocolate cookies made with premium ingredients',
      price: 150.0,
      mrp: 180.0,
      image: 'https://example.com/cookies.jpg',
      categoryId: 'bakeries_biscuits',
      categoryName: 'Bakery & Biscuits',
      subcategoryId: 'cookies',
      tags: ['cookies', 'chocolate', 'premium'],
      weight: '250g',
      brand: 'Sweet Treats',
      inStock: true,
    );
    
    // Create a bestseller item with percentage discount
    final bestsellerItem = BestsellerItem(
      productId: product.id,
      rank: 1,
      discountType: 'percentage',
      discountValue: 15.0, // 15% off
    );
    
    // Create the BestsellerProduct by combining the two
    final bestsellerProduct = BestsellerProduct(
      product: product,
      bestsellerInfo: bestsellerItem,
    );
    
    // Calculate the prices
    final originalPrice = product.price;
    final mrpPrice = product.mrp ?? originalPrice;
    final finalPrice = bestsellerProduct.finalPrice;
    final totalDiscount = mrpPrice - finalPrice;
    final totalDiscountPercentage = bestsellerProduct.totalDiscountPercentage.round();
    
    // Log the pricing details
    LoggingService.logFirestore(
      'CUSTOM_BESTSELLER: Original price: $originalPrice, MRP: $mrpPrice, ' +
      'Final price: $finalPrice, Total discount: $totalDiscount ($totalDiscountPercentage%)'
    );
    
    print(
      'CUSTOM_BESTSELLER: Original price: $originalPrice, MRP: $mrpPrice, ' +
      'Final price: $finalPrice, Total discount: $totalDiscount ($totalDiscountPercentage%)'
    );
    
    // Return card in a container
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card with bestseller discount
        Container(
          width: double.infinity,
          child: BestsellerProductCard(
            bestsellerProduct: bestsellerProduct,
            backgroundColor: Colors.blue.shade800,
            quantity: _cartQuantities[product.id] ?? 0,
            onTap: (bp) => _onProductTap(bp.product),
            onQuantityChanged: (bp, qty) => _onProductQuantityChanged(bp.product, qty),
            showBestsellerBadge: true,
          ),
        ),
        
        // Pricing breakdown
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pricing Breakdown:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              _buildPriceRow('MRP', mrpPrice, Colors.white70),
              _buildPriceRow('Regular Price', originalPrice, AppTheme.accentColor.withOpacity(0.7)),
              _buildPriceRow(
                'Bestseller Discount (15%)', 
                originalPrice * 0.15, 
                Colors.red,
                isDiscount: true
              ),
              Divider(color: Colors.white24),
              _buildPriceRow('Final Price', finalPrice, AppTheme.accentColor, isFinal: true),
              _buildPriceRow(
                'Total Savings', 
                totalDiscount, 
                Colors.green,
                isDiscount: true
              ),
              Text(
                'You save $totalDiscountPercentage% off MRP!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceRow(String label, double amount, Color color, {bool isDiscount = false, bool isFinal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
              fontSize: isFinal ? 16.sp : 14.sp,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
              fontSize: isFinal ? 16.sp : 14.sp,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiscountTypeExample(String type, String description, String example, Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Example: $example',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _onProductTap(Product product) {
    // Handle product tap
    LoggingService.logFirestore('BESTSELLER_EXAMPLE: Product tapped - ${product.name}');
    print('BESTSELLER_EXAMPLE: Product tapped - ${product.name}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped on ${product.name}')),
    );
  }

  void _onProductQuantityChanged(Product product, int quantity) {
    // Update cart quantities
    LoggingService.logFirestore(
      'BESTSELLER_EXAMPLE: Product quantity changed - ${product.name}, quantity: $quantity'
    );
    print('BESTSELLER_EXAMPLE: Product quantity changed - ${product.name}, quantity: $quantity');
    
    setState(() {
      if (quantity <= 0) {
        _cartQuantities.remove(product.id);
      } else {
        _cartQuantities[product.id] = quantity;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          quantity <= 0
              ? 'Removed ${product.name} from cart'
              : 'Updated ${product.name} to quantity $quantity'
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }
}