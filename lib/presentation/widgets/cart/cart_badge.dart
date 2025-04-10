import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/services/cart/cart_sync_service.dart';
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
          previous.total != current.total ||
          previous.syncStatus != current.syncStatus,
      builder: (context, state) {
        // Log cart state for debugging
        CartLogger.log('CART_BADGE', 'Building FloatingCartBadge with state: ${state.status}, itemCount: ${state.itemCount}');
        
        // Don't show if cart is empty
        if (state.itemCount == 0) {
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
            borderRadius: BorderRadius.circular(16.r),
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
                  horizontal: 16.r,
                  vertical: 12.r,
                ),
                child: Row(
                  children: [
                    // Cart icon with badge
                    badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -8, end: -8),
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
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: badgeSize,
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
                        if (state.syncStatus == CartSyncStatus.pendingSync ||
                            state.syncStatus == CartSyncStatus.syncing)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.syncStatus == CartSyncStatus.syncing
                                    ? Icons.sync
                                    : Icons.sync_problem,
                                color: state.syncStatus == CartSyncStatus.syncing
                                    ? Colors.amber
                                    : Colors.orange,
                                size: smallFontSize,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                state.syncStatus == CartSyncStatus.syncing
                                    ? 'Syncing...'
                                    : 'Pending sync',
                                style: TextStyle(
                                  color: state.syncStatus == CartSyncStatus.syncing
                                      ? Colors.amber
                                      : Colors.orange,
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
      buildWhen: (previous, current) => previous.syncStatus != current.syncStatus,
      builder: (context, state) {
        // Don't show if synced
        if (state.syncStatus == CartSyncStatus.synced) {
          return const SizedBox.shrink();
        }
        
        // Colors based on status
        Color color;
        IconData icon;
        String message;
        
        switch (state.syncStatus) {
          case CartSyncStatus.syncing:
            color = Colors.amber;
            icon = Icons.sync;
            message = 'Syncing cart...';
            break;
          case CartSyncStatus.pendingSync:
            color = Colors.orange;
            icon = Icons.sync_problem;
            message = 'Cart will sync when online';
            break;
          case CartSyncStatus.partialSync:
            color = Colors.orange;
            icon = Icons.sync_problem;
            message = 'Some cart items not synced';
            break;
          case CartSyncStatus.offline:
            color = Colors.red.shade300;
            icon = Icons.cloud_off;
            message = 'Offline mode';
            break;
          case CartSyncStatus.error:
            color = Colors.red;
            icon = Icons.error_outline;
            message = 'Sync error';
            break;
          default:
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
              if (state.syncStatus == CartSyncStatus.pendingSync ||
                  state.syncStatus == CartSyncStatus.partialSync ||
                  state.syncStatus == CartSyncStatus.error)
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