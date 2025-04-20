import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/firestore_product_card.dart';

/// A grid of products loaded from Firestore
class FirestoreProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;
  final Function(ProductModel, int) onQuantityChanged;
  final Map<String, int> cartQuantities;
  final int crossAxisCount;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Map<String, Color>? subCategoryColors;

  const FirestoreProductGrid({
    Key? key,
    required this.products,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities = const {},
    this.crossAxisCount = 2,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.subCategoryColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: products.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemBuilder: (context, index) {
        final product = products[index];
        final quantity = cartQuantities[product.id] ?? 0;
        
        // Get category-specific color if available
        Color? categoryColor;
        if (subCategoryColors != null && subCategoryColors!.containsKey(product.subcategoryId)) {
          categoryColor = subCategoryColors![product.subcategoryId];
        }
        
        return FirestoreProductCard(
          product: product,
          onTap: () => onProductTap(product),
          onQuantityChanged: (newQuantity) {
            onQuantityChanged(product, newQuantity);
          },
          quantity: quantity,
          categoryColor: categoryColor,
          showDiscountTag: product.hasDiscount && product.discountPercentage != null,
          discountPercent: product.discountPercentage != null 
            ? product.discountPercentage!.toInt() 
            : 0,
        );
      },
    );
  }
}