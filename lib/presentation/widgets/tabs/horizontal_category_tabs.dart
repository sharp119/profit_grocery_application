import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:profit_grocery_application/data/models/firestore/category_group_firestore_model.dart';

import '../../../core/constants/app_theme.dart';

/// A reusable widget for horizontal scrolling category tabs
/// Usually displayed at the top of the home screen
class HorizontalCategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final List<CategoryGroupFirestore>? categoryGroups;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool showNewBadge;
  final int? newTabIndex;

  const HorizontalCategoryTabs({
    Key? key,
    required this.tabs,
    this.categoryGroups,
    required this.selectedIndex,
    required this.onTabSelected,
    this.showNewBadge = false,
    this.newTabIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get actual device size and adjust accordingly
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    // Calculate responsive dimensions - adjust for smaller screens
    final containerHeight = isSmallScreen ? 70.0 : 80.0;
    final iconBoxSize = (screenWidth / 11).clamp(36.0, 46.0);
    final textSize = (screenWidth / 45).clamp(9.0, 11.0);
    
    return Container(
      height: containerHeight,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            final showBadge = showNewBadge && newTabIndex == index;
            
            // Calculate the width of each tab item to ensure proper distribution
            final screenWidth = MediaQuery.of(context).size.width;
            final visibleItemCount = 5.0; // Target showing 5 items on screen
            // Use a percentage of screen width, but enforce min/max constraints
            final itemWidth = (screenWidth / visibleItemCount).clamp(60.0, 80.0);
            
            // Get first category item image from the category group if available
            String? categoryImageUrl;
            if (categoryGroups != null && 
                index < categoryGroups!.length && 
                categoryGroups![index].items.isNotEmpty) {
              categoryImageUrl = categoryGroups![index].items.first.imagePath;
            }
            
            return Container(
              width: itemWidth,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tab image with optional "New" badge
                    Stack(
                      children: [
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            color: categoryImageUrl != null && categoryImageUrl.isNotEmpty
                                ? Colors.transparent
                                : AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(10.0),
                            // Remove the shadow for selected items
                          ),
                          child: categoryImageUrl != null && categoryImageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: CachedNetworkImage(
                                  imageUrl: categoryImageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white, // Changed from accent color
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.category,
                                    color: Colors.white, // Always white
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.category,
                                color: Colors.white, // Always white
                              ),
                        ),
                        
                        // "New" badge
                        if (showBadge)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Text(
                                'New',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    // Tab text
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: Colors.white, // Always white
                        fontSize: textSize,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}