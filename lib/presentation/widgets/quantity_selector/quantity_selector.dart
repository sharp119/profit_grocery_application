import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../utils/add_button_handler.dart';
import '../../../domain/entities/product.dart';

/// A reusable quantity selector widget with increment and decrement buttons
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;
  final bool alignHorizontal;
  final Color? accentColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final Product? product; // Add product parameter for the AddButtonHandler

  const QuantitySelector({
    Key? key,
    required this.quantity,
    required this.onChanged,
    this.alignHorizontal = true,
    this.accentColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accentColor;
    final bgColor = backgroundColor ?? Colors.black26;

    // Function to handle quantity change with AddButtonHandler integration
    void handleQuantityChange(int newQuantity) {
      // If changing from 0 to 1 and product is available, use AddButtonHandler
      if (quantity == 0 && newQuantity == 1 && product != null) {
        AddButtonHandler().handleAddButtonClick(
          product: product!,
          quantity: newQuantity,
          originalCallback: (_, qty) => onChanged(qty),
        );
      } else {
        // Otherwise, proceed with normal flow
        onChanged(newQuantity);
      }
    }

    if (alignHorizontal) {
      return Container(
        width: width,
        height: height ?? 36.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Decrement button
            IconButton(
              onPressed: quantity > 0 
                ? () => handleQuantityChange(quantity - 1)
                : null,
              icon: Icon(
                Icons.remove,
                color: quantity > 0 ? color : Colors.grey,
                size: 20.r,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 36.h,
              ),
            ),
            
            // Quantity display
            Expanded(
              child: Text(
                quantity.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            
            // Increment button
            IconButton(
              onPressed: () => handleQuantityChange(quantity + 1),
              icon: Icon(
                Icons.add,
                color: color,
                size: 20.r,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 36.h,
              ),
            ),
          ],
        ),
      );
    } else {
      // Vertical layout
      return Container(
        width: width ?? 36.w,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Increment button
            IconButton(
              onPressed: () => handleQuantityChange(quantity + 1),
              icon: Icon(
                Icons.add,
                color: color,
                size: 20.r,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 36.w,
                minHeight: 36.h,
              ),
            ),
            
            // Quantity display
            Container(
              height: 36.h,
              alignment: Alignment.center,
              child: Text(
                quantity.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            
            // Decrement button
            IconButton(
              onPressed: quantity > 0 
                ? () => handleQuantityChange(quantity - 1)
                : null,
              icon: Icon(
                Icons.remove,
                color: quantity > 0 ? color : Colors.grey,
                size: 20.r,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 36.w,
                minHeight: 36.h,
              ),
            ),
          ],
        ),
      );
    }
  }
}
