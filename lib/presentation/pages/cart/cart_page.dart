import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product/shared_product_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartProvider _cartProvider = CartProvider();
  final SharedProductService _productService = SharedProductService();
  
  // Map to track loading state and product details for each cart item
  final Map<String, bool> _loadingState = {};
  final Map<String, Product?> _productDetails = {};
  int _totalItems = 0;
  int _removedItems = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final cartItems = _cartProvider.cartItems;
    int totalCount = 0;
    int removedCount = 0;
    
    print('--- Cart Items Log ---');
    
    if (cartItems.isEmpty) {
      print('Cart is empty');
    } else {
      print('Total unique products in cart: ${cartItems.length}');
      
      // Initialize loading states for all products
      for (final entry in cartItems.entries) {
        final productId = entry.key;
        final quantity = entry.value['quantity'] as int? ?? 0;
        totalCount += quantity;
        
        // Set initial loading state
        setState(() {
          _loadingState[productId] = true;
          _totalItems = totalCount;
        });
        
        // Fetch product details from Firestore
        try {
          final product = await _productService.getProductById(productId);
          
          // Log product details
          print('\nProduct ID: $productId, Quantity: $quantity');
          if (product != null) {
            print('  Product name: ${product.name}');
            print('  Price: ${product.price}');
            print('  MRP: ${product.mrp ?? 'N/A'}');
            print('  Category: ${product.categoryName ?? 'N/A'}');
          } else {
            print('  Product details not found in Firestore');
            removedCount += quantity;
          }
          
          // Update product details and loading state
          setState(() {
            _productDetails[productId] = product;
            _loadingState[productId] = false;
            _removedItems = removedCount;
          });
        } catch (e) {
          print('  Error fetching product details: $e');
          setState(() {
            _loadingState[productId] = false;
            removedCount += quantity;
            _removedItems = removedCount;
          });
        }
      }
      
      print('\nTotal number of items: $totalCount');
      print('\nRemoved items: $removedCount');
    }
    
    print('---------------------');
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartProvider.cartItems;
    // Filter out unknown products
    final validCartItems = cartItems.keys
        .where((id) => _productDetails[id] != null)
        .toList();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64.r,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cart Items',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              '$_totalItems items',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_removedItems > 0)
                        Container(
                          margin: EdgeInsets.only(top: 8.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            _removedItems == 1
                                ? '1 item has been removed from the store'
                                : '$_removedItems items have been removed from the store',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: validCartItems.isEmpty
                      ? Center(
                          child: Text(
                            'No available products in cart',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
                          itemCount: validCartItems.length,
                          itemBuilder: (context, index) {
                            final productId = validCartItems[index];
                            final quantity = cartItems[productId]?['quantity'] as int? ?? 0;
                            final isLoading = _loadingState[productId] ?? true;
                            final product = _productDetails[productId];
                            
                            if (product == null) {
                              return SizedBox.shrink(); // Don't show removed products
                            }
                            
                            return isLoading
                                ? _buildLoadingCartItem()
                                : _buildCartItem(productId, product, quantity);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingCartItem() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ShimmerLoader.cartItem(
        height: 120.h,
      ),
    );
  }

  Widget _buildCartItem(String productId, Product? product, int quantity) {
    // Don't show removed products
    if (product == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with background color
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: _buildProductImage(product),
          ),
          SizedBox(width: 12.w),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                if (product.categoryName != null)
                  Text(
                    product.categoryName!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      '₹${product.price}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (product.mrp != null && product.mrp! > product.price)
                      Text(
                        '₹${product.mrp}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              'Qty: $quantity',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductImage(Product? product) {
    if (product == null) {
      return _buildImageErrorWidget();
    }
    
    final imageUrl = product.image;
    
    // Check for Firebase Storage URLs that cause errors (gs:// format)
    if (imageUrl.startsWith('gs://')) {
      return _buildImageErrorWidget();
    }
    
    // Check if URL is valid
    if (!imageUrl.startsWith('http')) {
      return _buildImageErrorWidget();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: ImageLoader.network(
        imageUrl,
        fit: BoxFit.contain,
        width: 80.w,
        height: 80.h,
        errorWidget: _buildImageErrorWidget(),
      ),
    );
  }
  
  Widget _buildImageErrorWidget() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textSecondaryColor,
        size: 24.sp,
      ),
    );
  }
}

