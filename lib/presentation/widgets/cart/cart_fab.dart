import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../services/cart_provider.dart';

class CartFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? elevation;

  const CartFAB({
    Key? key,
    required this.onPressed,
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
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main FAB
        FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: backgroundColor,
          elevation: widget.elevation ?? 6.0,
          child: Icon(
            Icons.shopping_cart,
            color: iconColor,
          ),
        ),
        
        // Item count badge
        if (_itemCount > 0)
          Positioned(
            top: -8.r,
            right: -5.r,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 20.r,
                minHeight: 20.r,
              ),
              child: Center(
                child: Text(
                  _itemCount > 99 ? '99+' : _itemCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 