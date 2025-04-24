import 'package:flutter/material.dart';
import '../../../domain/entities/product.dart';
import '../../../models/discount_model.dart';
import '../../../services/discount/discount_provider.dart';
import '../../../services/logging_service.dart';
import 'reusable_product_card.dart';

/// A modern product card that uses the new discount system
/// This card fetches discount information automatically for any product
class ModernProductCard extends StatefulWidget {
  final Product product;
  final Color backgroundColor;
  final Function(Product)? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;

  const ModernProductCard({
    Key? key,
    required this.product,
    required this.backgroundColor,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
  }) : super(key: key);

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard> {
  final DiscountProvider _discountProvider = DiscountProvider();
  DiscountModel? _discountModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscount();
  }

  @override
  void didUpdateWidget(ModernProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload discount if product changed
    if (oldWidget.product.id != widget.product.id) {
      _loadDiscount();
    }
  }

  // Load discount information using the discount provider
  Future<void> _loadDiscount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get discount from the discount provider
      final discount = await _discountProvider.getDiscount(widget.product);
      
      if (mounted) {
        setState(() {
          _discountModel = discount;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggingService.logError('PRODUCT_CARD', 'Error loading discount: $e');
      
      if (mounted) {
        setState(() {
          // Create a fallback model with no discount
          _discountModel = DiscountModel.noDiscount(
            productId: widget.product.id,
            price: widget.product.price,
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If discount is still loading, show loading state
    if (_isLoading) {
      return _buildLoadingCard();
    }

    // Calculate original price to show (either MRP or product price)
    final originalPrice = widget.product.mrp != null && widget.product.mrp! > _discountModel!.finalPrice 
        ? widget.product.mrp 
        : _discountModel!.hasDiscount 
            ? _discountModel!.originalPrice 
            : null;

    // Use the reusable product card with discount data from our system
    return ReusableProductCard(
      product: widget.product,
      finalPrice: _discountModel!.finalPrice,
      originalPrice: originalPrice,
      hasDiscount: _discountModel!.hasDiscount,
      discountType: _discountModel!.discountType,
      discountValue: _discountModel!.discountValue,
      backgroundColor: widget.backgroundColor,
      onTap: widget.onTap,
      onQuantityChanged: widget.onQuantityChanged,
      quantity: widget.quantity,
    );
  }
  
  // Loading placeholder
  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}