import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';

import '../../../core/constants/app_theme.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../pages/cart/cart_page.dart';

/// A cart badge widget that shows the number of items in the cart
/// and navigates to the cart page when tapped.
class CartBadge extends StatelessWidget {
  /// Creates a cart badge in the app bar
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => previous.itemCount != current.itemCount,
      builder: (context, state) {
        // Scale based on screen size
        final iconSize = (24.0).r;
        final badgeSize = (8.0).r.clamp(8.0, 12.0);
        
        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: -5, end: -5),
          showBadge: state.itemCount > 0,
          badgeContent: state.itemCount > 0
              ? Text(
                  state.itemCount > 99 ? '99+' : '${state.itemCount}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: badgeSize,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          badgeStyle: badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: AppTheme.accentColor,
            padding: EdgeInsets.all(state.itemCount > 99 ? 4.r : 5.r),
            elevation: 3,
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            iconSize: iconSize,
            color: Colors.white,
            onPressed: () {
              // Navigate to cart page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        );
      },
    );
  }
}

/// A floating cart badge that shows at the bottom of the screen
class FloatingCartBadge extends StatelessWidget {
  const FloatingCartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => 
          previous.itemCount != current.itemCount ||
          previous.total != current.total,
      builder: (context, state) {
        // Log cart state for debugging
        CartLogger.log('CART_BADGE', 'Building FloatingCartBadge with state: ${state.status}, itemCount: ${state.itemCount}');
        
        // Don't show if cart is empty
        if (state.itemCount <= 0 || state.total <= 0) {
          CartLogger.info('CART_BADGE', 'Cart is empty, not showing floating badge');
          return const SizedBox.shrink();
        }
        
        final screenWidth = MediaQuery.of(context).size.width;
        final fontSize = (16.0).sp.clamp(14.0, 18.0);
        final smallFontSize = (12.0).sp.clamp(10.0, 14.0);
        final badgeSize = (18.0).sp.clamp(16.0, 20.0);
        
        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24.r),
            color: AppTheme.secondaryColor,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // Navigate to cart page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              child: Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: 18.r,
                  vertical: 14.r,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  children: [
                    // Cart icon with badge - improved circular container
                    badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      showBadge: state.itemCount > 0,
                      badgeContent: Text(
                        state.itemCount > 99 ? '99+' : '${state.itemCount}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        shape: badges.BadgeShape.circle,
                        badgeColor: AppTheme.accentColor,
                        padding: EdgeInsets.all(4.r),
                        elevation: 3,
                      ),
                      child: Container(
                        width: badgeSize * 1.5,
                        height: badgeSize * 1.5,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: badgeSize,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Items count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.itemCount} ${state.itemCount == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: smallFontSize,
                          ),
                        ),
                        if (state.status == CartStatus.syncing)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                color: Colors.amber,
                                size: smallFontSize,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Syncing...',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: smallFontSize * 0.8,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Total and view cart button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${state.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: smallFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small indicator for the cart sync status
class CartSyncIndicator extends StatelessWidget {
  const CartSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        // Only show if syncing or error
        if (state.status != CartStatus.syncing && state.status != CartStatus.error) {
          return const SizedBox.shrink();
        }
        
        // Colors based on status
        Color color;
        IconData icon;
        String message;
        
        if (state.status == CartStatus.syncing) {
          color = Colors.amber;
          icon = Icons.sync;
          message = 'Syncing cart...';
        } else if (state.status == CartStatus.error) {
          color = Colors.red;
          icon = Icons.error_outline;
          message = 'Sync error';
        } else {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 14.r,
              ),
              SizedBox(width: 4.w),
              Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                ),
              ),
              if (state.status == CartStatus.error)
                IconButton(
                  iconSize: 14.r,
                  padding: EdgeInsets.all(4.r),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.refresh,
                    color: color,
                  ),
                  onPressed: () {
                    context.read<CartBloc>().add(const ForceSync());
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}