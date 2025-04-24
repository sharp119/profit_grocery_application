import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

/// A simple button with no cart functionality (cart not yet implemented)
class CartFAB extends StatelessWidget {
  final VoidCallback onTap;
  final String? previewImagePath;

  const CartFAB({
    Key? key,
    required this.onTap,
    this.previewImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show "Coming Soon" button
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              // Shopping cart icon
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.black,
                  size: 20.r,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // View cart text with enhanced typography
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}