import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../core/constants/app_theme.dart';

/// A reusable carousel banner for promotional content
class PromotionalBanner extends StatefulWidget {
  final List<String> images;
  final List<String>? titles;
  final List<String>? subtitles;
  final List<VoidCallback>? onTapCallbacks;
  final double? height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool enlargeCenterPage;
  final bool showIndicator;
  final BoxFit imageFit;
  final double viewportFraction;

  const PromotionalBanner({
    Key? key,
    required this.images,
    this.titles,
    this.subtitles,
    this.onTapCallbacks,
    this.height,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.enlargeCenterPage = true,
    this.showIndicator = true,
    this.imageFit = BoxFit.cover,
    this.viewportFraction = 0.85,
  }) : super(key: key);

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height ?? 180.h,
            viewportFraction: widget.viewportFraction,
            enableInfiniteScroll: widget.images.length > 1,
            autoPlay: widget.autoPlay && widget.images.length > 1,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: widget.enlargeCenterPage,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: List.generate(widget.images.length, (index) {
            return Builder(
              builder: (BuildContext context) {
                // Whether this banner has a title and subtitle
                final hasTitle = widget.titles != null && 
                    index < widget.titles!.length && 
                    widget.titles![index].isNotEmpty;
                final hasSubtitle = widget.subtitles != null && 
                    index < widget.subtitles!.length && 
                    widget.subtitles![index].isNotEmpty;
                
                // Whether this banner is tappable
                final isTappable = widget.onTapCallbacks != null && 
                    index < widget.onTapCallbacks!.length;
                
                return GestureDetector(
                  onTap: isTappable ? widget.onTapCallbacks![index] : null,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Stack(
                        children: [
                          // Banner image
                          Positioned.fill(
                            child: Image.asset(
                              widget.images[index],
                              fit: widget.imageFit,
                            ),
                          ),
                          
                          // Gradient overlay for text readability (if there's text)
                          if (hasTitle || hasSubtitle)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          
                          // Title and subtitle
                          if (hasTitle || hasSubtitle)
                            Positioned(
                              bottom: 16.h,
                              left: 16.w,
                              right: 16.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasTitle)
                                    Text(
                                      widget.titles![index],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  if (hasTitle && hasSubtitle)
                                    SizedBox(height: 4.h),
                                  
                                  if (hasSubtitle)
                                    Text(
                                      widget.subtitles![index],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                          // Shop now button
                          if (isTappable)
                            Positioned(
                              bottom: 16.h,
                              right: 16.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Shop Now',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                      size: 14.sp,
                                    ),
                                  ],
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
          }),
        ),
        
        // Carousel indicators
        if (widget.showIndicator && widget.images.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () {
                    // Simply update the UI to show this indicator as active
                    setState(() {
                      _currentIndex = entry.key;
                    });
                    // Note: Direct control of carousel position removed as it's causing compatibility issues
                    // Users can still swipe to navigate the carousel
                  },
                  child: Container(
                    width: _currentIndex == entry.key ? 18.w : 10.w,
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: _currentIndex == entry.key
                          ? AppTheme.accentColor
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}