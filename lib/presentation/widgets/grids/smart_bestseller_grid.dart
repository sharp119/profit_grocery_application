import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../domain/entities/product.dart';
import '../../../data/repositories/bestseller_repository.dart';
import '../../../services/logging_service.dart';
import '../cards/smart_product_card.dart';

/// A grid that displays bestseller products using smart product cards
/// Fetches bestsellers on its own and handles its own state management
class SmartBestsellerGrid extends StatefulWidget {
  final Function(Product) onProductTap;
  final Function(Product, int) onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;
  final Map<String, Color>? subcategoryColors;

  const SmartBestsellerGrid({
    Key? key,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 6,
    this.ranked = true,
    this.crossAxisCount = 2,
    this.subcategoryColors,
  }) : super(key: key);

  @override
  State<SmartBestsellerGrid> createState() => _SmartBestsellerGridState();
}

class _SmartBestsellerGridState extends State<SmartBestsellerGrid> {
  late final BestsellerRepository _bestsellerRepository;
  List<String> _bestsellerIds = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _bestsellerRepository = GetIt.instance<BestsellerRepository>();
    _loadBestsellerIds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh if the widget is hot reloaded
    if (_bestsellerIds.isEmpty && !_isLoading) {
      _loadBestsellerIds();
    }
  }

  Future<void> _loadBestsellerIds() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Fetch bestseller products with specified limit and ranking
      final products = await _bestsellerRepository.getBestsellerProducts(
        limit: widget.limit,
        ranked: widget.ranked,
      );

      // Extract just the product IDs
      final productIds = products.map((product) => product.id).toList();

      LoggingService.logFirestore(
          'SmartBestsellerGrid: Loaded ${productIds.length} bestseller IDs');

      setState(() {
        _bestsellerIds = productIds;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.logError(
          'SmartBestsellerGrid', 'Error loading bestseller IDs: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load bestsellers';
        _isLoading = false;
      });
    }
  }

  // Force refresh method that can be called from parent
  void refresh() {
    _loadBestsellerIds();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_bestsellerIds.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGrid();
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 220.h,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 220.h,
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40.r,
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadBestsellerIds,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 220.h,
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber,
            size: 40.r,
          ),
          SizedBox(height: 8.h),
          Text(
            'No bestseller products found',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 8.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: 0.75, // Adjust for desired height/width ratio
        crossAxisSpacing: 8.r,
        mainAxisSpacing: 8.r,
      ),
      itemCount: _bestsellerIds.length,
      itemBuilder: (context, index) {
        final productId = _bestsellerIds[index];
        final quantity = widget.cartQuantities?[productId] ?? 0;
        
        // Try to get color from subcategory colors map
        Color? backgroundColor;
        if (widget.subcategoryColors != null) {
          // This will be set correctly by the SmartProductCard as it knows the product details
          backgroundColor = null;
        }
        
        return SmartProductCard(
          productId: productId,
          onTap: widget.onProductTap,
          onQuantityChanged: widget.onQuantityChanged,
          quantity: quantity,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}
