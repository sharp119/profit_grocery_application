import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../domain/entities/product.dart';
import '../../../data/repositories/rtdb_bestseller_repository.dart';
import '../../../services/logging_service.dart';
import '../cards/rtdb_product_card.dart';
import '../../../core/constants/app_theme.dart';

/**
 * RTDBBestsellerGrid
 * 
 * A high-performance bestseller grid using the new Firebase RTDB structure.
 * This widget significantly reduces network load by fetching complete product 
 * information in minimal calls, replacing the previous multi-step Firestore approach.
 * 
 * Key Features:
 * - Single network call approach for bestseller data
 * - Real-time updates as RTDB data changes
 * - Integrated discount display (₹X off / X% off)
 * - Category-based background colors
 * - Smart pricing (MRP vs discounted price)
 * - Optimized performance
 * 
 * Usage:
 * ```dart
 * RTDBBestsellerGrid(
 *   onProductTap: (product) => navigateToProduct(product),
 *   onQuantityChanged: (product, qty) => updateCart(product, qty),
 *   cartQuantities: cartQuantities,
 *   limit: 4,
 *   ranked: false,
 * )
 * ```
 */

class RTDBBestsellerGrid extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;
  final bool showBestsellerBadge;
  final bool useRealTimeUpdates;

  const RTDBBestsellerGrid({
    Key? key,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 4,
    this.ranked = false,
    this.crossAxisCount = 2,
    this.showBestsellerBadge = true,
    this.useRealTimeUpdates = true,
  }) : super(key: key);

  @override
  State<RTDBBestsellerGrid> createState() => _RTDBBestsellerGridState();
  
  /// Get the state to access refresh functionality from parent widgets
  static _RTDBBestsellerGridState? of(BuildContext context) {
    return context.findAncestorStateOfType<_RTDBBestsellerGridState>();
  }
}

class _RTDBBestsellerGridState extends State<RTDBBestsellerGrid> {
  final RTDBBestsellerRepository _repository = RTDBBestsellerRepository();
  
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<List<Product>>? _streamSubscription;
  
  @override
  void initState() {
    super.initState();
    if (widget.useRealTimeUpdates) {
      _setupRealTimeStream();
    } else {
      _loadProducts();
    }
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
  
  /// Refresh data manually
  Future<void> refreshData() async {
    LoggingService.logFirestore('RTDB_GRID: Manual refresh requested');
    print('RTDB_GRID: Manual refresh requested');
    
    await _repository.refreshBestsellerData();
    
    if (!widget.useRealTimeUpdates) {
      await _loadProducts();
    }
  }

  /// Setup real-time stream for live updates
  void _setupRealTimeStream() {
    try {
      LoggingService.logFirestore('RTDB_GRID: Setting up real-time stream for bestsellers');
      print('RTDB_GRID: Setting up real-time stream for bestsellers');
      
      // Cancel existing subscription if any
      _streamSubscription?.cancel();
      
      // Use the optimized stream that listens to specific product changes
      _streamSubscription = _repository.getBestsellerProductsStreamOptimized(
        limit: widget.limit,
        ranked: widget.ranked,
      ).listen(
        (products) {
          if (mounted) {
            setState(() {
              _products = products;
              _isLoading = false;
              _hasError = false;
            });
            
            LoggingService.logFirestore('RTDB_GRID: Real-time update - ${products.length} products loaded');
            print('RTDB_GRID: Real-time update - ${products.length} products loaded');
            
            // Log product details for debugging
            for (final product in products) {
              LoggingService.logFirestore(
                'RTDB_GRID: Updated product - ${product.name}: MRP: ${product.mrp}, Price: ${product.price}, '
                'Discount: ${product.customProperties?['hasDiscount'] ?? false}'
              );
              print(
                'RTDB_GRID: Updated product - ${product.name}: MRP: ${product.mrp}, Price: ${product.price}, '
                'Discount: ${product.customProperties?['hasDiscount'] ?? false}'
              );
            }
          }
        },
        onError: (error) {
          LoggingService.logError('RTDB_GRID', 'Real-time stream error: $error');
          print('RTDB_GRID ERROR: Real-time stream error - $error');
          
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Failed to load bestsellers: $error';
              _isLoading = false;
            });
          }
        },
        onDone: () {
          LoggingService.logFirestore('RTDB_GRID: Real-time stream closed');
          print('RTDB_GRID: Real-time stream closed');
        },
      );
    } catch (e) {
      LoggingService.logError('RTDB_GRID', 'Error setting up real-time stream: $e');
      print('RTDB_GRID ERROR: Failed to setup stream - $e');
      _loadProducts(); // Fallback to one-time load
    }
  }

  /// Load products once (without real-time updates)
  Future<void> _loadProducts() async {
    try {
      LoggingService.logFirestore('RTDB_GRID: Loading bestseller products');
      print('RTDB_GRID: Loading bestseller products');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final products = await _repository.getBestsellerProducts(
        limit: widget.limit,
        ranked: widget.ranked,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        
        LoggingService.logFirestore('RTDB_GRID: Successfully loaded ${products.length} bestseller products');
        print('RTDB_GRID: Successfully loaded ${products.length} bestseller products');
      }
    } catch (e) {
      LoggingService.logError('RTDB_GRID', 'Error loading products: $e');
      print('RTDB_GRID ERROR: Failed to load products - $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load bestsellers';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGrid();
  }

  Widget _buildLoadingState() {
    LoggingService.logFirestore('RTDB_GRID: Rendering loading state');
    print('RTDB_GRID: Rendering loading state');
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.78, // Increased to give more height
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.limit,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
            border: Border.all(
              color: Colors.black.withOpacity(0.02),
              width: 1.w,
            ),
          ),
          child: Column(
            children: [
              // Image placeholder
              Container(
                height: 160.h, // Match new image section height
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accentColor,
                    strokeWidth: 2.w,
                  ),
                ),
              ),
              
              // Content placeholders
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price placeholder
                      Container(
                        width: 80.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      
                      // Weight placeholder
                      Container(
                        width: 60.w,
                        height: 13.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      
                      // Discount placeholder
                      Container(
                        width: 50.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      
                      SizedBox(height: 8.h),
                      
                      // Name placeholder
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    LoggingService.logFirestore('RTDB_GRID: Rendering error state - $_errorMessage');
    print('RTDB_GRID: Rendering error state - $_errorMessage');
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                if (widget.useRealTimeUpdates) {
                  _setupRealTimeStream();
                } else {
                  _loadProducts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    LoggingService.logFirestore('RTDB_GRID: Rendering empty state');
    print('RTDB_GRID: Rendering empty state');
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white54,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'No bestseller products found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Check back later for amazing deals!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final quantities = widget.cartQuantities ?? <String, int>{};
    
    LoggingService.logFirestore('RTDB_GRID: Rendering grid with ${_products.length} products');
    print('RTDB_GRID: Rendering grid with ${_products.length} products');

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.78, // Increased to give more height
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final product = _products[index];
        final quantity = quantities[product.id] ?? 0;
        
        LoggingService.logFirestore(
          'RTDB_GRID: Building card for ${product.name} - '
          'Price: ${product.price}, MRP: ${product.mrp}, '
          'Quantity: $quantity, InStock: ${product.inStock}'
        );

        return RTDBProductCard(
          product: product,
          onTap: widget.onProductTap,
          onQuantityChanged: widget.onQuantityChanged,
          quantity: quantity,
          showBestsellerBadge: false,  // Disabled by default
        );
      },
    );
  }
}
