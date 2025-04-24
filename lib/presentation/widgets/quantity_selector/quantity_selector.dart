import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../utils/add_button_handler.dart';
import '../../../domain/entities/product.dart';

/// A simplified selector that just shows an ADD button (cart not implemented yet)
class QuantitySelector extends StatelessWidget {
  final Product? product;
  final Color? accentColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const QuantitySelector({
    Key? key,
    this.product,
    this.accentColor,
    this.backgroundColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accentColor;
    final bgColor = backgroundColor ?? Colors.black26;

    // Just show the ADD button
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 36.h,
      child: ElevatedButton(
        onPressed: () {
          if (product != null) {
            // Use the centralized AddButtonHandler
            AddButtonHandler().handleAddButtonClick(
              productId: product!.id,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
