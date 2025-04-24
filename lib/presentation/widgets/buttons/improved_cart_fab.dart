import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_theme.dart';
import '../../../presentation/blocs/cart/cart_bloc.dart';
import '../../../presentation/blocs/cart/cart_state.dart';
import '../../../services/cart/improved_cart_service.dart';
import '../../../utils/cart_logger.dart';

/// An improved floating action button for the cart
/// This ensures visibility when there are items in the cart
/// and connects directly to the improved cart service
class ImprovedCartFAB extends StatefulWidget {
  final VoidCallback onTap;
  final String? previewImagePath;
  final bool showPreview;

  const ImprovedCartFAB({
    Key? key,
    required this.onTap,
    this.previewImagePath,
    this.showPreview = true,
  }) : super(key: key);

  @override
  State<ImprovedCartFAB> createState() => _ImprovedCartFABState();
}

class _ImprovedCartFABState extends State<ImprovedCartFAB> {
  final ImprovedCartService _cartService = GetIt.instance<ImprovedCartService>();
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCartService();
  }
  
  Future<void> _initializeCartService() async {
    if (!_initialized) {
      await _cartService.initialize();
      _initialized = true;
      
      // Force a rebuild after initialization
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        // Determine if we should show the widget based on cart state
        final bool hasItems = state.itemCount > 0 || _cartService.hasItems;
        final int itemCount = state.itemCount > 0 ? state.itemCount : _cartService.totalItems;
        final double totalAmount = state.total > 0 ? state.total : 0;
        
        CartLogger.log('IMPROVED_CART_FAB', 'Building FAB with hasItems: $hasItems, itemCount: $itemCount');
        
        // Don't show when cart is empty
        if (!hasItems) {
          return const SizedBox.shrink();
        }
        
        // Calculate responsive image size based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        final imageSize = (screenWidth * 0.12).clamp(42.0, 54.0);
        final badgeSize = (imageSize * 0.35).clamp(16.0, 22.0);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24.r),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
                // Add subtle gradient for premium look
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor,
                    AppTheme.accentColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // Add subtle border for depth
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item preview with badge
                  if (widget.showPreview && widget.previewImagePath != null)
                    badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      badgeAnimation: const badges.BadgeAnimation.slide(),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.black,
                        padding: EdgeInsets.all(badgeSize * 0.25),
                        borderSide: BorderSide(
                          color: AppTheme.accentColor,
                          width: 1.5,
                        ),
                        elevation: 2,
                      ),
                      badgeContent: Text(
                        itemCount.toString(),
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: (badgeSize * 0.5).clamp(10.0, 14.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          // Enhanced shadow for depth - premium look
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: EdgeInsets.all(imageSize * 0.05), // Minimal padding for maximum image
                            child: Image.asset(
                              widget.previewImagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                CartLogger.error('IMPROVED_CART_FAB', 'Error loading image: $error');
                                // Return a fallback icon if image fails to load
                                return Icon(
                                  Icons.shopping_bag,
                                  color: Colors.black,
                                  size: imageSize * 0.6,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      badgeAnimation: const badges.BadgeAnimation.slide(),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.black,
                        padding: EdgeInsets.all(badgeSize * 0.25),
                        borderSide: BorderSide(
                          color: AppTheme.accentColor,
                          width: 1.5,
                        ),
                        elevation: 2,
                      ),
                      badgeContent: Text(
                        itemCount.toString(),
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: (badgeSize * 0.5).clamp(10.0, 14.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                          size: imageSize * 0.6,
                        ),
                      ),
                    ),
                  
                  SizedBox(width: 12.w),
                  
                  // View cart text with enhanced typography
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View cart',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      
                      // Show total amount with premium styling
                      if (totalAmount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          margin: EdgeInsets.only(top: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // Enhanced arrow icon
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black,
                        size: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}