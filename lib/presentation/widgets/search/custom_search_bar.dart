import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final String hintText;
  final Color backgroundColor;
  final Color textColor;
  final Color? hintColor;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;

  const CustomSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText = 'Search products',
    this.backgroundColor = AppTheme.secondaryColor,
    this.textColor = Colors.white,
    this.hintColor,
    this.iconColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.readOnly = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor ?? Colors.white.withOpacity(0.5),
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: iconColor ?? Colors.white.withOpacity(0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.h,
            horizontal: 16.w,
          ),
        ),
        style: TextStyle(
          color: textColor,
          fontSize: 14.sp,
        ),
        cursorColor: AppTheme.accentColor,
        onChanged: onSearch,
        onTap: onTap,
      ),
    );
  }
} 