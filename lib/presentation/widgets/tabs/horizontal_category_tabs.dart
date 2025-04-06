import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

/// A reusable widget for horizontal scrolling category tabs
/// Usually displayed at the top of the home screen
class HorizontalCategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final List<IconData>? icons;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool showNewBadge;
  final int? newTabIndex;

  const HorizontalCategoryTabs({
    Key? key,
    required this.tabs,
    this.icons,
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
    final iconSize = (screenWidth / 27).clamp(14.0, 22.0);
    
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
                    // Tab icon with optional "New" badge
                    Stack(
                      children: [
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.accentColor.withOpacity(0.2) 
                                : AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.accentColor 
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            // Add subtle shadow for better visibility
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            icons != null && index < icons!.length 
                                ? icons![index] 
                                : Icons.category,
                            color: isSelected ? AppTheme.accentColor : Colors.white,
                            size: iconSize,
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
                        color: isSelected ? AppTheme.accentColor : Colors.white,
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