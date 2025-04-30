import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/discount/discount_service.dart';

/// A widget that displays discount information for a product
/// Uses the DiscountService to get discount details by product ID
class DiscountDisplayWidget extends StatefulWidget {
  final String productId;
  final Color backgroundColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const DiscountDisplayWidget({
    Key? key,
    required this.productId,
    this.backgroundColor = Colors.red,
    this.fontSize,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<DiscountDisplayWidget> createState() => _DiscountDisplayWidgetState();
}

class _DiscountDisplayWidgetState extends State<DiscountDisplayWidget> {
  Map<String, dynamic>? _discountInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscountInfo();
  }
  
  @override
  void didUpdateWidget(DiscountDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadDiscountInfo();
    }
  }

  Future<void> _loadDiscountInfo() async {
    // Check cache first
    final cachedInfo = DiscountService.getCachedDiscountInfo(widget.productId);
    if (cachedInfo != null) {
      setState(() {
        _discountInfo = cachedInfo;
        _isLoading = false;
      });
      return;
    }
    
    // If not in cache, load asynchronously
    setState(() {
      _isLoading = true;
    });
    
    try {
      final info = await DiscountService.getProductDiscountInfo(widget.productId);
      if (mounted) {
        setState(() {
          _discountInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading discount info: $e');
      if (mounted) {
        setState(() {
          _discountInfo = {'hasDiscount': false, 'error': e.toString()};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if loading or no discount
    if (_isLoading || _discountInfo == null || !(_discountInfo!['hasDiscount'] as bool)) {
      return const SizedBox.shrink();
    }

    final discountPercentage = _discountInfo!['discountPercentage'];
    
    return Container(
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius ?? BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomLeft: Radius.circular(12.r),
        ),
      ),
      child: Text(
        '$discountPercentage% OFF',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize ?? 10.sp,
        ),
      ),
    );
  }
} 