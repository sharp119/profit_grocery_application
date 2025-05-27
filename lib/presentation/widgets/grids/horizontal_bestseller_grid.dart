import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../domain/entities/bestseller_item.dart';
import '../../../data/repositories/bestseller_repository_simple.dart';
import '../../../data/repositories/rtdb_bestseller_repository.dart';
import '../../../services/logging_service.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../utils/product_card_utils.dart';
import '../cards/improved_product_card.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'package:get_it/get_it.dart';

/**
 * HorizontalBestsellerGrid
 * 
 * A horizontally scrollable grid component specifically designed for the bestsellers section
 * on the home screen. This grid displays product cards in a single row with horizontal scrolling,
 * showing 2 full cards and part of a third card for visual indication of more content.
 * 
 * Key Features:
 * - Horizontal scrolling with fixed card widths
 * - Shows 2 full cards + partial 3rd card for scroll indication
 * - Dynamic loading as user scrolls (pagination)
 * - Real-time updates via RTDB or static data
 * - Optimized performance with improved product cards
 * - Category-based background colors
 * - Special bestseller pricing and discounts
 * 
 * Layout Specifications:
 * - Card Width: Fixed at 140.w for consistent spacing (optimized for 2.33 cards)
 * - Visible Cards: 2.33 cards (2 full + 0.33 partial)
 * - Spacing: 12.w between cards
 * - Padding: 16.w horizontal margins
 * - Height: Responsive based on card content
 * 
 * Usage:
 * ```dart
 * HorizontalBestsellerGrid(
 *   onProductTap: (product) => navigateToProduct(product),
 *   onQuantityChanged: (product, qty) => updateCart(product, qty),
 *   cartQuantities: cartQuantities,
 *   limit: 12,
 *   useRealTimeUpdates: true,
 * )
 * ```
 */

class HorizontalBestsellerGrid extends StatefulWidget {
  // Core callbacks
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  
  // Configuration
  final int limit;
  final bool ranked;
  final bool useRealTimeUpdates;
  final bool showBestsellerBadge;
  
  // Layout customization
  final double cardWidth;
  final double cardHeight;
  final double spacing;
  final EdgeInsets? padding;
  
  // Data source selection
  final bool useRTDB; // true for RTDB, false for simple bestseller repository

  const HorizontalBestsellerGrid({
    Key? key,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 12,
    this.ranked = false,
    this.useRealTimeUpdates = true,
    this.showBestsellerBadge = false,
    this.cardWidth = AppConstants.horizontalCardWidth,
    this.cardHeight = AppConstants.horizontalCardHeight,
    this.spacing = AppConstants.horizontalCardSpacing,
    this.padding,
    this.useRTDB = true, // Default to RTDB for better performance
  }) : super(key: key);

  @override
  State<HorizontalBestsellerGrid> createState() => _HorizontalBestsellerGridState();
}

class _HorizontalBestsellerGridState extends State<HorizontalBestsellerGrid> {
  // Repositories
  RTDBBestsellerRepository? _rtdbRepository;
  BestsellerRepositorySimple? _simpleRepository;
  
  // Services
  late final SharedProductService _productService;
  late final SharedCategoryService _categoryService;
  
  // State management
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<List<Product>>? _streamSubscription;
  
  // Scroll management
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentLimit = AppConstants.horizontalGridPageSize; // Start with page size, then increase
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _initializeServices() {
    _productService = GetIt.instance<SharedProductService>();
    _categoryService = GetIt.instance<SharedCategoryService>();
    
    if (widget.useRTDB) {
      _rtdbRepository = RTDBBestsellerRepository();
    } else {
      _simpleRepository = BestsellerRepositorySimple();
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }
  
  Future<void> _loadInitialData() async {
    try {
      LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Loading initial data');
      print('HORIZONTAL_BESTSELLER: Loading initial data');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentLimit = AppConstants.horizontalGridPageSize;
        _hasMoreData = true;
      });
      
      if (widget.useRTDB && widget.useRealTimeUpdates) {
        await _setupRealTimeStream();
      } else {
        await _loadData();
      }
      
    } catch (e) {
      LoggingService.logError('HORIZONTAL_BESTSELLER', 'Error loading initial data: $e');
      print('HORIZONTAL_BESTSELLER ERROR: Failed to load initial data - $e');
      
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load bestsellers: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setupRealTimeStream() async {
    try {
      LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Setting up real-time stream');
      print('HORIZONTAL_BESTSELLER: Setting up real-time stream');
      
      _streamSubscription?.cancel();
      
      _streamSubscription = _rtdbRepository!.getBestsellerProductsStreamOptimized(
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
            
            LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Real-time update - ${products.length} products');
            print('HORIZONTAL_BESTSELLER: Real-time update - ${products.length} products');
          }
        },
        onError: (error) {
          LoggingService.logError('HORIZONTAL_BESTSELLER', 'Real-time stream error: $error');
          print('HORIZONTAL_BESTSELLER ERROR: Real-time stream error - $error');
          
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Failed to load bestsellers: $error';
              _isLoading = false;
            });
          }
        },
      );
      
    } catch (e) {
      LoggingService.logError('HORIZONTAL_BESTSELLER', 'Error setting up stream: $e');
      print('HORIZONTAL_BESTSELLER ERROR: Failed to setup stream - $e');
      
      // Fallback to one-time load
      await _loadData();
    }
  }
  
  Future<void> _loadData() async {
    try {
      LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Loading data (limit: $_currentLimit)');
      print('HORIZONTAL_BESTSELLER: Loading data (limit: $_currentLimit)');
      
      List<Product> newProducts = [];
      
      if (widget.useRTDB) {
        // Load from RTDB - repositories don't support offset, so we use limit
        newProducts = await _rtdbRepository!.getBestsellerProducts(
          limit: _currentLimit,
          ranked: widget.ranked,
        );
      } else {
        // Load from simple repository - repositories don't support offset, so we use limit
        final bestsellerItems = await _simpleRepository!.getBestsellerItems(
          limit: _currentLimit,
          ranked: widget.ranked,
        );
        
        // Convert bestseller items to products
        for (final item in bestsellerItems) {
          final product = await _productService.getProductById(item.productId);
          if (product != null) {
            newProducts.add(product);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _products = newProducts;
          _isLoading = false;
          _isLoadingMore = false;
          
          // Check if we have more data (if we got fewer items than requested or reached the widget limit)
          _hasMoreData = newProducts.length >= _currentLimit && _currentLimit < widget.limit;
        });
        
        LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Loaded ${newProducts.length} products');
        print('HORIZONTAL_BESTSELLER: Loaded ${newProducts.length} products');
      }
      
    } catch (e) {
      LoggingService.logError('HORIZONTAL_BESTSELLER', 'Error loading data: $e');
      print('HORIZONTAL_BESTSELLER ERROR: Failed to load data - $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (_products.isEmpty) {
            _hasError = true;
            _errorMessage = 'Failed to load bestsellers: $e';
          }
        });
      }
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || widget.useRealTimeUpdates) return;
    
    LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Loading more data');
    print('HORIZONTAL_BESTSELLER: Loading more data');
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Increase the limit to load more items (since repositories don't support offset)
    _currentLimit = (_currentLimit + AppConstants.horizontalGridPageSize).clamp(0, widget.limit);
    
    await _loadData();
  }
  
  Future<void> refreshData() async {
    LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Manual refresh requested');
    print('HORIZONTAL_BESTSELLER: Manual refresh requested');
    
    if (widget.useRTDB) {
      await _rtdbRepository?.refreshBestsellerData();
    }
    
    if (!widget.useRealTimeUpdates) {
      await _loadInitialData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _products.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError && _products.isEmpty) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildHorizontalGrid();
  }
  
  Widget _buildLoadingState() {
    return SizedBox(
      height: widget.cardHeight.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show 3 loading cards
        padding: widget.padding ?? ProductCardUtils.horizontalListPadding,
        itemBuilder: (context, index) {
          return Container(
            width: widget.cardWidth.w,
            margin: EdgeInsets.only(
              right: index < 2 ? widget.spacing.w : 0,
            ),
            child: ImprovedProductCard.loading(
              width: widget.cardWidth.w,
              height: widget.cardHeight.h,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      height: widget.cardHeight.h,
      padding: widget.padding ?? ProductCardUtils.horizontalListPadding,
      child: Center(
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
              onPressed: _loadInitialData,
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
    return Container(
      height: widget.cardHeight.h,
      padding: widget.padding ?? ProductCardUtils.horizontalListPadding,
      child: Center(
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
  
  Widget _buildHorizontalGrid() {
    final cartQuantities = widget.cartQuantities ?? <String, int>{};
    
    LoggingService.logFirestore('HORIZONTAL_BESTSELLER: Building horizontal grid with ${_products.length} products');
    print('HORIZONTAL_BESTSELLER: Building horizontal grid with ${_products.length} products');

    return SizedBox(
      height: widget.cardHeight.h,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _products.length + (_isLoadingMore ? 1 : 0),
        padding: widget.padding ?? ProductCardUtils.horizontalListPadding,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == _products.length && _isLoadingMore) {
            return Container(
              width: widget.cardWidth.w,
              margin: EdgeInsets.only(left: widget.spacing.w),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                  strokeWidth: 2.w,
                ),
              ),
            );
          }
          
          final product = _products[index];
          final quantity = cartQuantities[product.id] ?? 0;
          
          LoggingService.logFirestore(
            'HORIZONTAL_BESTSELLER: Building card ${index + 1} for ${product.name} (quantity: $quantity)'
          );
          
          return Container(
            width: widget.cardWidth.w,
            margin: ProductCardUtils.getCardMargin(index, _products.length, spacing: widget.spacing.w),
            child: ImprovedProductCard(
              product: product,
              width: widget.cardWidth.w,
              height: widget.cardHeight.h,
              onTap: widget.onProductTap != null 
                ? () => widget.onProductTap!(product)
                : null,
              onQuantityChanged: widget.onQuantityChanged,
              quantity: quantity,
              showSavingsIndicator: widget.showBestsellerBadge,
            ),
          );
        },
      ),
    );
  }
}

/**
 * HorizontalBestsellerSection
 * 
 * A complete section component that includes the section header and the horizontal
 * bestseller grid. This is a convenience widget for easy integration into pages.
 */
class HorizontalBestsellerSection extends StatelessWidget {
  final String title;
  final String? viewAllText;
  final VoidCallback? onViewAllTap;
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final bool useRealTimeUpdates;
  final bool showBestsellerBadge;

  const HorizontalBestsellerSection({
    Key? key,
    this.title = 'Bestsellers',
    this.viewAllText = 'View All',
    this.onViewAllTap,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 12,
    this.ranked = false,
    this.useRealTimeUpdates = true,
    this.showBestsellerBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (onViewAllTap != null && viewAllText != null)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    viewAllText!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Horizontal Grid
        HorizontalBestsellerGrid(
          onProductTap: onProductTap,
          onQuantityChanged: onQuantityChanged,
          cartQuantities: cartQuantities,
          limit: limit,
          ranked: ranked,
          useRealTimeUpdates: useRealTimeUpdates,
          showBestsellerBadge: showBestsellerBadge,
        ),
      ],
    );
  }
}
