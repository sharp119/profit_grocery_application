import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/cart.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/cards/cart_item_card.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Placeholder cart items (will be fetched from cart repository in a real app)
  final List<CartItem> _cartItems = [
    CartItem(
      productId: '1',
      name: 'Fresh Organic Tomatoes',
      price: 49.0,
      quantity: 2,
      image: '${AppConstants.assetsProductsPath}1.png',
    ),
    CartItem(
      productId: '2',
      name: 'Premium Basmati Rice 5kg',
      price: 299.0,
      quantity: 1,
      image: '${AppConstants.assetsProductsPath}2.png',
    ),
    CartItem(
      productId: '3',
      name: 'Whole Wheat Atta 10kg',
      price: 450.0,
      quantity: 1,
      image: '${AppConstants.assetsProductsPath}3.png',
    ),
  ];
  
  String _couponCode = ''; // Store coupon code
  double _discount = 0.0; // Placeholder discount
  bool _isCouponApplied = false; // Is coupon applied flag
  bool _isApplyingCoupon = false; // Loading state for coupon application

  void _updateCartItemQuantity(String productId, int quantity) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        if (quantity <= 0) {
          _cartItems.removeAt(index);
          
          // Reset coupon if cart becomes empty
          if (_cartItems.isEmpty) {
            _resetCoupon();
          }
        } else {
          final item = _cartItems[index];
          _cartItems[index] = CartItem(
            productId: item.productId,
            name: item.name,
            image: item.image,
            price: item.price,
            quantity: quantity,
          );
        }
      }
    });
  }

  void _removeCartItem(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.productId == productId);
      
      // Reset coupon if cart becomes empty
      if (_cartItems.isEmpty) {
        _resetCoupon();
      }
    });
  }

  void _resetCoupon() {
    setState(() {
      _couponCode = '';
      _discount = 0.0;
      _isCouponApplied = false;
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _resetCoupon();
    });
  }

  void _applyCoupon() async {
    if (_couponCode.isEmpty || _isApplyingCoupon) return;
    
    setState(() {
      _isApplyingCoupon = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    final subtotal = _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    setState(() {
      _isApplyingCoupon = false;
      _isCouponApplied = true;
      _discount = subtotal * 0.1; // 10% discount
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon applied successfully! You saved ${AppConstants.currencySymbol}${_discount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'My Cart',
      actions: [
        if (_cartItems.isNotEmpty)
          TextButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(
              'Clear',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartWithItems(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add items to your cart to start shopping',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate back to home
              Navigator.pop(context);
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems() {
    // Calculate cart totals
    final subtotal = _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    final deliveryFee = 40.0; // Placeholder delivery fee
    final total = subtotal - _discount + deliveryFee;

    return Column(
      children: [
        // Cart items list
        Expanded(
          child: ListView.builder(
            itemCount: _cartItems.length,
            padding: EdgeInsets.all(16.w),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              
              return CartItemCard.fromEntity(
                item: item,
                onQuantityChanged: (newQuantity) {
                  _updateCartItemQuantity(item.productId, newQuantity);
                },
                onRemove: () {
                  _removeCartItem(item.productId);
                },
              );
            },
          ),
        ),
        
        // Cart summary and checkout
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coupon section
              _buildCouponSection(subtotal),
              
              SizedBox(height: 16.h),
              
              // Price summary
              _buildPriceSummary(subtotal, deliveryFee, total),
              
              SizedBox(height: 16.h),
              
              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutPage(),
                      ),
                    );
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCouponSection(double subtotal) {
    return !_isCouponApplied
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply Coupon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _couponCode = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  ElevatedButton(
                    onPressed: _couponCode.isEmpty || _isApplyingCoupon
                        ? null
                        : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: _isApplyingCoupon
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
            ],
          )
        : Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.accentColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: AppTheme.accentColor,
                  size: 20.sp,
                ),
                
                SizedBox(width: 8.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Applied: $_couponCode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 4.h),
                      
                      Text(
                        'You saved ${AppConstants.currencySymbol}${_discount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: _resetCoupon,
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
  }

  Widget _buildPriceSummary(double subtotal, double deliveryFee, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        _buildPriceRow('Subtotal', '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}'),
        
        SizedBox(height: 4.h),
        
        if (_discount > 0) ...[
          _buildPriceRow(
            'Discount',
            '- ${AppConstants.currencySymbol}${_discount.toStringAsFixed(2)}',
            isDiscount: true,
          ),
          
          SizedBox(height: 4.h),
        ],
        
        _buildPriceRow('Delivery Fee', '${AppConstants.currencySymbol}${deliveryFee.toStringAsFixed(2)}'),
        
        SizedBox(height: 8.h),
        
        const Divider(color: Colors.grey),
        
        SizedBox(height: 8.h),
        
        _buildPriceRow(
          'Total',
          '${AppConstants.currencySymbol}${total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : isTotal
                    ? Colors.white
                    : Colors.grey,
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : isTotal
                    ? AppTheme.accentColor
                    : Colors.white,
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}