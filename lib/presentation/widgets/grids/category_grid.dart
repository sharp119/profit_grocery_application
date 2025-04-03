import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../domain/entities/category.dart';
import '../cards/category_card.dart';

/// A reusable staggered grid view for displaying category cards
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;
  final bool useStaggeredLayout;
  final double? cardHeight;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final int? crossAxisCount;

  const CategoryGrid({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
    this.useStaggeredLayout = true,
    this.cardHeight,
    this.padding,
    this.physics,
    this.crossAxisCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (useStaggeredLayout) {
      return _buildStaggeredGrid();
    } else {
      return _buildRegularGrid();
    }
  }

  /// Build a staggered grid layout for categories
  Widget _buildStaggeredGrid() {
    return MasonryGridView.count(
      crossAxisCount: crossAxisCount ?? 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      shrinkWrap: true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        
        // Promotional categories get double height in staggered layout
        final isPromotional = category.type == 'promotional';
        final heightMultiplier = isPromotional ? 1.5 : 1.0;
        
        return CategoryCard.fromEntity(
          category: category,
          onTap: () => onCategoryTap(category),
          height: cardHeight != null 
              ? cardHeight! * heightMultiplier 
              : null,
        );
      },
    );
  }

  /// Build a regular grid layout for categories
  Widget _buildRegularGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount ?? 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.9, // Adjust aspect ratio as needed
      ),
      shrinkWrap: true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        
        return CategoryCard.fromEntity(
          category: category,
          onTap: () => onCategoryTap(category),
          height: cardHeight,
        );
      },
    );
  }
}