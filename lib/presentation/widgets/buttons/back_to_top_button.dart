import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

/// A floating button that appears during scrolling to allow users to quickly 
/// return to the top of a scrollable view
class BackToTopButton extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const BackToTopButton({
    Key? key,
    required this.onTap,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward,
                color: AppTheme.accentColor,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Back to top',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create a back to top button that appears conditionally based on scroll position
  static Widget scrollAware({
    required ScrollController scrollController,
    required VoidCallback onTap,
    double showAtOffset = 300.0,
    EdgeInsetsGeometry? margin,
  }) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final show = scrollController.hasClients && 
                    scrollController.offset > showAtOffset;
                    
        return AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: show
              ? BackToTopButton(
                  onTap: onTap,
                  margin: margin,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}