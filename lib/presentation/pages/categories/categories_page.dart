import 'package:flutter/material.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';
import 'package:profit_grocery_application/data/models/firestore/category_group_firestore_model.dart';
import 'package:profit_grocery_application/presentation/widgets/panels/two_panel_category_product_view.dart';
import 'package:profit_grocery_application/presentation/widgets/buttons/cart_fab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_theme.dart';
import 'package:profit_grocery_application/domain/entities/category.dart';
import 'package:profit_grocery_application/presentation/pages/category_products/category_products_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: Implement search navigation
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<List<CategoryGroupFirestore>>(
        future: SharedCategoryService().getAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load categories'));
          }
          final groups = snapshot.data ?? [];
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 100.h),
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final group = groups[groupIndex];
              return Padding(
                padding: EdgeInsets.only(bottom: 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _CategoryGroupGrid(
                      group: group,
                      onCategoryTap: (item) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsPage(
                              categoryId: item.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: CartFAB(onTap: () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _CategoryGroupGrid extends StatelessWidget {
  final CategoryGroupFirestore group;
  final void Function(CategoryItemFirestore) onCategoryTap;
  const _CategoryGroupGrid({required this.group, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final items = group.items;
    // Ensure we have at least 8 items for the layout
    final paddedItems = List<CategoryItemFirestore>.from(items);
    while (paddedItems.length < 8) {
      paddedItems.add(CategoryItemFirestore(id: '', label: '', imagePath: '', description: ''));
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          // First row: first item spans 2 columns, then 2 regular items
          Row(
            children: [
              // First item (spans 2 columns)
              Expanded(
                flex: 2,
                child: _CategoryCard(
                  item: paddedItems[0],
                  onTap: onCategoryTap,
                  isLarge: true,
                  backgroundColor: group.itemBackgroundColor,
                ),
              ),
              SizedBox(width: 12.w),
              // Second item
              Expanded(
                flex: 1,
                child: _CategoryCard(
                  item: paddedItems[1],
                  onTap: onCategoryTap,
                  isLarge: false,
                  backgroundColor: group.itemBackgroundColor,
                ),
              ),
              SizedBox(width: 12.w),
              // Third item
              Expanded(
                flex: 1,
                child: _CategoryCard(
                  item: paddedItems[2],
                  onTap: onCategoryTap,
                  isLarge: false,
                  backgroundColor: group.itemBackgroundColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Second row: 4 regular items
          Row(
            children: [
              for (int i = 3; i < 7; i++) ...[
                Expanded(
                  child: _CategoryCard(
                    item: paddedItems[i],
                    onTap: onCategoryTap,
                    isLarge: false,
                    backgroundColor: group.itemBackgroundColor,
                  ),
                ),
                if (i != 6) SizedBox(width: 12.w),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItemFirestore item;
  final void Function(CategoryItemFirestore) onTap;
  final bool isLarge;
  final Color backgroundColor;
  const _CategoryCard({required this.item, required this.onTap, required this.isLarge, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final isEmpty = item.id.isEmpty;
    return GestureDetector(
      onTap: isEmpty ? null : () => onTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isLarge ? 18.r : 16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isLarge ? 14.r : 8.r),
        height: isLarge ? 120.h : 90.h,
        width: isLarge ? 120.w : 90.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: item.imagePath.isEmpty
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(isLarge ? 14.r : 12.r),
                      child: Image.network(
                        item.imagePath,
                        fit: BoxFit.contain,
                        width: isLarge ? 70.w : 48.w,
                        height: isLarge ? 70.h : 48.h,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: isLarge ? 40.sp : 28.sp, color: Colors.grey),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                        },
                      ),
                    ),
            ),
            SizedBox(height: 8.h),
            if (!isEmpty)
              Text(
                item.label,
                style: TextStyle(
                  fontSize: isLarge ? 15.sp : 13.sp,
                  fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
} 