import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../services/cart_provider.dart';
import '../../../utils/add_button_handler.dart';

enum ProductCardType {
  simple,
  reusable,
  enhanced,
  quantitySelector,
  productDetails
}

class AddButton extends StatefulWidget {
  final String productId;
  final ProductCardType sourceCardType;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? fontSize;
  final bool inStock;

  const AddButton({
    Key? key,
    required this.productId,
    required this.sourceCardType,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.fontSize,
    this.inStock = true,
  }) : super(key: key);

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  int _quantity = 0;
  final CartProvider _cartProvider = CartProvider();

  @override
  void initState() {
    super.initState();
    // Check if this product is already in the cart
    _loadCartQuantity();
    
    // Listen for cart changes
    _cartProvider.addListener(_onCartChanged);
  }
  
  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    _cartProvider.removeListener(_onCartChanged);
    super.dispose();
  }
  
  void _onCartChanged() {
    _loadCartQuantity();
  }
  
  void _loadCartQuantity() {
    final quantity = _cartProvider.getQuantity(widget.productId);
    
    if (quantity != _quantity) {
      setState(() {
        _quantity = quantity;
      });
    }
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
    _logAction("plus");
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
      _logAction("minus");
    } else if (_quantity == 1) {
      setState(() {
        _quantity = 0;
      });
      _logAction("minus");
    }
  }

  void _handleAddClick() {
    setState(() {
      _quantity = 1;
    });
    _logAction("add");
  }

  void _logAction(String action) {
    final cardType = widget.sourceCardType.toString().split('.').last;
    
    print('Button action: $action');
    print('Product Card: $cardType');
    print('Product ID: ${widget.productId}');
    print('Current quantity: $_quantity');
    
    AddButtonHandler().handleAddButtonClick(
      productId: widget.productId,
      quantity: _quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.backgroundColor ?? AppTheme.accentColor;
    final buttonTextColor = widget.textColor ?? Colors.black;
    final buttonHeight = widget.height ?? 36.h;
    final textSize = widget.fontSize ?? 14.sp;

    // If not in stock or quantity is zero, show the ADD button
    if (!widget.inStock || _quantity == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: SizedBox(
          height: buttonHeight,
          width: double.infinity, // Will adapt to parent width
          child: ElevatedButton(
            onPressed: widget.inStock ? _handleAddClick : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.inStock ? buttonColor : Colors.grey.shade700,
              foregroundColor: buttonTextColor,
              disabledBackgroundColor: Colors.grey.shade700,
              disabledForegroundColor: Colors.white70,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child: Text(
              widget.inStock ? 'ADD' : 'Out of Stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: textSize,
              ),
            ),
          ),
        ),
      );
    }

    // If quantity is greater than zero, show the quantity selector
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        height: buttonHeight,
        width: double.infinity, // Will adapt to parent width
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Decrease button
            InkWell(
              onTap: _decreaseQuantity,
              child: SizedBox(
                width: buttonHeight, // Square button
                height: buttonHeight,
                child: Center(
                  child: Icon(
                    Icons.remove,
                    color: buttonTextColor,
                    size: textSize + 2.sp,
                  ),
                ),
              ),
            ),
            
            // Quantity display
            Text(
              _quantity.toString(),
              style: TextStyle(
                color: buttonTextColor,
                fontWeight: FontWeight.bold,
                fontSize: textSize,
              ),
            ),
            
            // Increase button
            InkWell(
              onTap: _increaseQuantity,
              child: SizedBox(
                width: buttonHeight, // Square button
                height: buttonHeight,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: buttonTextColor,
                    size: textSize + 2.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 