import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;

import '../../core/constants/app_theme.dart';
import '../pages/cart/cart_page.dart';

/// A reusable base layout widget for consistent UI across screens
class BaseLayout extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  final bool showBackButton;
  final bool showCartIcon;
  final int cartItemCount;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onCartTap;

  const BaseLayout({
    Key? key,
    required this.title,
    this.actions = const [],
    required this.body,
    this.showBackButton = true,
    this.showCartIcon = true,
    this.cartItemCount = 0,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onCartTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get device screen size for responsive components
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive sizes
    final badgePadding = (screenWidth / 85).clamp(4.0, 6.0);
    final badgeFontSize = (screenWidth / 40).clamp(10.0, 14.0);
    final actionSpacing = (screenWidth / 50).clamp(4.0, 8.0);
    
    // Generate app bar actions
    final appBarActions = <Widget>[...actions];
    
    // Add cart icon if needed
    if (showCartIcon) {
      appBarActions.add(
        badges.Badge(
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          badgeAnimation: const badges.BadgeAnimation.slide(),
          badgeStyle: badges.BadgeStyle(
            badgeColor: AppTheme.accentColor,
            padding: EdgeInsets.all(badgePadding),
          ),
          badgeContent: Text(
            cartItemCount.toString(),
            style: TextStyle(
              color: Colors.black,
              fontSize: badgeFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: onCartTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ),
      );
      
      appBarActions.add(SizedBox(width: actionSpacing));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showBackButton ? null : const SizedBox.shrink(),
        automaticallyImplyLeading: showBackButton,
        actions: appBarActions,
      ),
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  /// Create a base layout with cart floating action button
  static Widget withCartFAB({
    required String title,
    List<Widget> actions = const [],
    required Widget body,
    bool showBackButton = true,
    bool showCartIcon = true,
    required int cartItemCount,
    Widget? bottomNavigationBar,
    required VoidCallback onCartTap,
  }) {
    return Builder(
      builder: (context) {
        // Get screen dimensions for responsive UI
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Calculate responsive dimensions
        final badgePadding = (screenWidth / 85).clamp(4.0, 6.0);
        final badgeFontSize = (screenWidth / 40).clamp(10.0, 14.0);
        final fabLabelSize = (screenWidth / 30).clamp(14.0, 16.0);
        
        return BaseLayout(
          title: title,
          actions: actions,
          body: body,
          showBackButton: showBackButton,
          showCartIcon: showCartIcon,
          cartItemCount: cartItemCount,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: cartItemCount > 0
              ? badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -10, end: -10),
                  badgeAnimation: const badges.BadgeAnimation.slide(),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: AppTheme.accentColor,
                    padding: EdgeInsets.all(badgePadding),
                  ),
                  badgeContent: Text(
                    cartItemCount.toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use standard FAB on very small screens
                      if (screenWidth < 320) {
                        return FloatingActionButton(
                          onPressed: onCartTap,
                          backgroundColor: AppTheme.accentColor,
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.black,
                          ),
                        );
                      }
                      // Use extended FAB on larger screens
                      return FloatingActionButton.extended(
                        onPressed: onCartTap,
                        label: Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: fabLabelSize,
                          ),
                        ),
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                        ),
                        backgroundColor: AppTheme.accentColor,
                      );
                    }
                  ),
                )
              : null,
        );
      }
    );
  }
}