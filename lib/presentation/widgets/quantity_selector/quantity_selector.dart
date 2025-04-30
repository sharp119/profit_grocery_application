import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../widgets/buttons/add_button.dart';
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

    if (product == null) {
      return SizedBox(); // Return empty widget if no product
    }

    // Use the centralized AddButton widget
    return AddButton(
      productId: product!.id,
      sourceCardType: ProductCardType.quantitySelector,
      backgroundColor: color,
      height: height ?? 36.h,
      inStock: product!.inStock,
    );
  }
}
