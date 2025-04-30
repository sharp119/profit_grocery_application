import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../services/cart_provider.dart';

/// A simple button with no cart functionality (cart not yet implemented)
class CartFAB extends StatefulWidget {
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? elevation;

  const CartFAB({
    Key? key,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.elevation,
  }) : super(key: key);

  @override
  State<CartFAB> createState() => _CartFABState();
}

class _CartFABState extends State<CartFAB> {
  final CartProvider _cartProvider = CartProvider();
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _updateItemCount();
    
    // Listen to cart changes
    _cartProvider.addListener(_onCartChanged);
  }
  
  @override
  void dispose() {
    _cartProvider.removeListener(_onCartChanged);
    super.dispose();
  }
  
  void _onCartChanged() {
    _updateItemCount();
  }
  
  void _updateItemCount() {
    final cartItems = _cartProvider.cartItems;
    int count = 0;
    
    cartItems.forEach((productId, item) {
      count += (item['quantity'] as int? ?? 0);
    });
    
    setState(() {
      _itemCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppTheme.accentColor;
    final iconColor = widget.iconColor ?? Colors.black;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
            // Add subtle gradient for premium look
            gradient: LinearGradient(
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // Add subtle border for depth
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shopping cart icon with count
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Colors.black,
                      size: 20.r,
                    ),
                  ),
                  
                  // Item count badge
                  if (_itemCount > 0)
                    Positioned(
                      top: -5.r,
                      right: -5.r,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.r,
                          minHeight: 16.r,
                        ),
                        child: Center(
                          child: Text(
                            _itemCount > 99 ? '99+' : _itemCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(width: 12.w),
              
              // View cart text
              Text(
                _itemCount > 0 ? 'View Cart' : 'Cart',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}