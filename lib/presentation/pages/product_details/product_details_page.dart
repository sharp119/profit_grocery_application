import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:profit_grocery_application/domain/entities/product.dart'; // Product entity (for RTDB data)
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart'; // Firestore service (for raw sections)
import 'package:profit_grocery_application/services/rtdb_product_service.dart'; // RTDB service (for dynamic Product)
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/presentation/widgets/buttons/add_button.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/loaders/shimmer_loader.dart';
import 'package:profit_grocery_application/services/logging_service.dart';
import 'package:profit_grocery_application/presentation/widgets/image_loader.dart';


class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final String? categoryId;
  final String? subcategoryId;

  const ProductDetailsPage({
    Key? key,
    required this.productId,
    this.categoryId,
    this.subcategoryId,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? _firestoreRawData; // Raw sections from Firestore
  Product? _dynamicProductDetails; // Parsed Product from RTDB (for dynamic data)

  bool _isLoadingFirestore = true;
  bool _isLoadingRTDB = true;
  bool _hasErrorFirestore = false;
  bool _hasErrorRTDB = false;
  String? _errorMessage;

  // Overall loading/error state for the UI
  bool _isLoadingOverall = true;
  bool _hasErrorOverall = false;

  late final FirestoreProductService _firestoreProductService;
  late final RTDBProductService _rtdbProductService;
  StreamSubscription<Product?>? _rtdbStreamSubscription;

  // For Image Carousel
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _firestoreProductService = GetIt.instance<FirestoreProductService>();
    _rtdbProductService = GetIt.instance<RTDBProductService>();
    _pageController = PageController(); // Initialize PageController

    _fetchStaticDataFromFirestore();
    _setupDynamicStreamFromRTDB();
  }

  @override
  void dispose() {
    _rtdbStreamSubscription?.cancel();
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  // Fetches static product sections data from Firestore
  Future<void> _fetchStaticDataFromFirestore() async {
    setState(() {
      _isLoadingFirestore = true;
      _hasErrorFirestore = false;
    });

    if (widget.categoryId == null || widget.subcategoryId == null) {
      setState(() {
        _isLoadingFirestore = false;
        _hasErrorFirestore = true;
        _errorMessage = 'Category ID or Subcategory ID is missing for Firestore path.';
      });
      LoggingService.logError('ProductDetailsPage', _errorMessage!);
      _updateOverallLoadingState(); // Update overall state
      return;
    }

    try {
      final fetchedData = await _firestoreProductService.getProductSectionsById(
        widget.productId,
        widget.categoryId!,
        widget.subcategoryId!,
      );

      if (mounted) {
        setState(() {
          _firestoreRawData = fetchedData;
          _isLoadingFirestore = false;
          _hasErrorFirestore = (fetchedData == null);
          if (fetchedData == null) {
            _errorMessage = 'Static product sections not found in Firestore.';
          }
        });
        LoggingService.logFirestore('ProductDetailsPage: Fetched static sections from Firestore for ${widget.productId}.');
      }
    } catch (e) {
      LoggingService.logError('ProductDetailsPage', 'Error fetching static sections from Firestore: $e');
      if (mounted) {
        setState(() {
          _isLoadingFirestore = false;
          _hasErrorFirestore = true;
          _errorMessage = 'Failed to load static product sections from Firestore: $e';
        });
      }
    } finally {
      _updateOverallLoadingState(); // Always update overall state
    }
  }

  // Sets up a real-time stream for dynamic product details from RTDB
  void _setupDynamicStreamFromRTDB() {
    setState(() {
      _isLoadingRTDB = true;
      _hasErrorRTDB = false;
    });

    _rtdbStreamSubscription?.cancel();

    _rtdbStreamSubscription = _rtdbProductService.getProductStream(widget.productId).listen(
      (product) {
        if (mounted) {
          setState(() {
            _dynamicProductDetails = product;
            _isLoadingRTDB = false;
            _hasErrorRTDB = (product == null);
            if (product == null) {
              _errorMessage = 'Dynamic product details not found or became unavailable.';
            }
          });
          LoggingService.logFirestore('ProductDetailsPage: Stream updated for ${widget.productId}. Dynamic Product: ${product?.name ?? 'Not found'}');
          _updateOverallLoadingState(); // Update overall state on new data
        }
      },
      onError: (error) {
        LoggingService.logError('ProductDetailsPage', 'Error in dynamic product stream for ${widget.productId}: $error');
        if (mounted) {
          setState(() {
            _isLoadingRTDB = false;
            _hasErrorRTDB = true;
            _errorMessage = 'Failed to load dynamic product details: $error';
          });
          _updateOverallLoadingState(); // Update overall state on error
        }
      },
      onDone: () {
        LoggingService.logFirestore('ProductDetailsPage: Dynamic product stream for ${widget.productId} is done.');
        _updateOverallLoadingState(); // Update overall state when stream is done
      },
    );
  }

  // Updates overall loading and error state for the UI
  void _updateOverallLoadingState() {
    setState(() {
      _isLoadingOverall = _isLoadingFirestore || _isLoadingRTDB;
      _hasErrorOverall = _hasErrorFirestore || _hasErrorRTDB || (_firestoreRawData == null && _dynamicProductDetails == null);

      if (_hasErrorOverall && _errorMessage == null) {
        // Fallback generic error message if a specific one wasn't set by sub-fetches
        _errorMessage = 'Failed to load complete product details.';
      }
    });
  }

    // Helper for safely casting to double/int from raw data
    double? _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    int? _toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingOverall) {
      return _buildLoadingState();
    }

    if (_hasErrorOverall || _firestoreRawData == null) { // Must have static data at least
      return _buildErrorState();
    }

    // Now, combine data from _firestoreRawData (static) and _dynamicProductDetails (dynamic) for display

    final Map<String, dynamic> combinedData = _firestoreRawData!; // Base from Firestore

    // Overlay dynamic properties from RTDB product onto the combined map
    final double displayPrice = _dynamicProductDetails?.price ?? 0.0;
    final double? displayMrp = _dynamicProductDetails?.mrp;
    final bool displayInStock = _dynamicProductDetails?.inStock ?? false;
    final String? dynamicDiscountType = _dynamicProductDetails?.customProperties?['discountType'] as String?;
    final double? dynamicDiscountValue = _dynamicProductDetails?.customProperties?['discountValue'] as double?;
    final bool dynamicHasDiscount = _dynamicProductDetails?.hasDiscount ?? false;


    // Extracting fields from combined raw Firestore data for display
    final Map<String, dynamic>? heroSection = combinedData['hero_section'] as Map<String, dynamic>?;
    final Map<String, dynamic>? highlightsSection = combinedData['highlights_section'] as Map<String, dynamic>?;
    final Map<String, dynamic>? descriptionSection = combinedData['description_section'] as Map<String, dynamic>?;
    final Map<String, dynamic>? sellerInfoSection = combinedData['seller_info_section'] as Map<String, dynamic>?;
    final Map<String, dynamic>? additionalInfo = combinedData['additional_info'] as Map<String, dynamic>?;

    // Static fields (from Firestore raw data)
    final String productName = heroSection?['name'] as String? ?? 'Unnamed Product';
    final String productDescription = descriptionSection?['description'] as String? ?? 'No description available for this product.';
    final List<dynamic> productImages = (heroSection?['images'] as List?)?.map((e) => e.toString()).toList() ?? []; // Get all images
    final String? productBrand = heroSection?['brand'] as String?;
    final double? productRating = _toDouble(heroSection?['rating']);
    final int? productReviewCount = _toInt(heroSection?['reviewCount']);
    final String? productType = heroSection?['productType'] as String?;
    final String? productSku = additionalInfo?['sku'] as String?;
    final List<String> productTags = (additionalInfo?['tags'] as List?)?.map((tag) => tag.toString()).toList() ?? [];
    final String? sellerName = sellerInfoSection?['sellerName'] as String?;
    final String? productWeight = (highlightsSection?['highlights'] as Map<String, dynamic>?)?['Weight'] as String? ?? (highlightsSection?['highlights'] as Map<String, dynamic>?)?['Pack Quantity'] as String?;
    final String? nutritionalInfo = (highlightsSection?['highlights'] as Map<String, dynamic>?)?['Nutritional Info'] as String?;
    // Get itemBackgroundColor from RTDB product custom properties
    final Color? itemBackgroundColorFromRTDB = _dynamicProductDetails?.customProperties?['itemBackgroundColor'] as Color?;


  

    // Dynamic pricing calculations remain the same, using dynamic data
    final bool showDiscountStrikethrough = (displayMrp != null && displayMrp > displayPrice);


    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          productName, // From Firestore
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Carousel (Hero Section Visual)
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 350.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      // Use itemBackgroundColor from RTDB, fallback to secondaryColor
                      color: itemBackgroundColorFromRTDB ?? AppTheme.secondaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: (productImages.isNotEmpty)
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: productImages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return ImageLoader.network(
                                  productImages[index], // From Firestore images list
                                  fit: BoxFit.contain,
                                  errorWidget: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppTheme.textSecondaryColor,
                                      size: 60.r,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center( // Fallback if no images are found
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.textSecondaryColor,
                                size: 60.r,
                              ),
                            ),
                    ),
                  ),
                ),
                // Discount Badge (on image)
                if (dynamicHasDiscount && dynamicDiscountValue != null && dynamicDiscountValue > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        maxWidth: 60.w, // Adjust max width as needed
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12.r),
                          topLeft: Radius.circular(8.r), // Match container's top left
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dynamicDiscountType == 'percentage'
                                ? '${dynamicDiscountValue.toInt()}%'
                                : '₹${dynamicDiscountValue.toInt()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.sp,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.sp,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Page Indicator
                if (productImages.length > 1)
                  Positioned(
                    bottom: 10.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(productImages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          height: 8.h,
                          width: _currentPage == index ? 24.w : 8.w,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppTheme.accentColor : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),

            // Product Name and Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName, // From Firestore
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (productRating != null && productRating > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        productRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (productReviewCount != null && productReviewCount > 0)
                        Text(
                          ' (${productReviewCount} reviews)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 8.h),

            // Brand and Weight/Product Type
            Row(
              children: [
                if (productBrand != null && productBrand.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      productBrand, // From Firestore
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (productBrand != null && productBrand.isNotEmpty && (productWeight != null || productType != null))
                  SizedBox(width: 8.w),
                if (productWeight != null && productWeight.isNotEmpty)
                  Text(
                    productWeight, // From Firestore
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                if (productWeight == null && productType != null && productType.isNotEmpty)
                  Text(
                    productType, // From Firestore
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Price Section (using dynamic pricing from RTDB) with Add Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Price Display
                Text(
                  '${AppConstants.currencySymbol}${displayPrice.toStringAsFixed(0)}', // From RTDB
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: dynamicHasDiscount ? Colors.green[700] : AppTheme.accentColor,
                  ),
                ),
                if (showDiscountStrikethrough) ...[
                  SizedBox(width: 10.w),
                  Text(
                    '${AppConstants.currencySymbol}${displayMrp!.toStringAsFixed(0)}', // From RTDB
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppTheme.textSecondaryColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  if (dynamicDiscountValue != null)
                    Text(
                      dynamicDiscountType == 'percentage'
                          ? '${dynamicDiscountValue.toInt()}% OFF'
                          : '₹${dynamicDiscountValue.toInt()} OFF',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
                Spacer(), // Pushes AddButton to the right
                // Add to Cart Button
                if (displayInStock)
                  SizedBox(
                    width: 100.w, // Fixed width for the button
                    height: 40.h, // Fixed height for the button
                    child: AddButton(
                      productId: widget.productId,
                      sourceCardType: ProductCardType.productDetails,
                      inStock: displayInStock, // From RTDB
                    ),
                  )
                else
                  Container(
                    width: 100.w,
                    height: 40.h,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'SOLD OUT', // Changed from 'OUT OF STOCK' for brevity
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),

            // Product Description
            if (productDescription.isNotEmpty) ...[
              Text(
                'About this item',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                productDescription, // From Firestore
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // Highlights Section
            if (highlightsSection != null && highlightsSection['highlights'] is Map) ...[
              Text(
                'Product Highlights',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (highlightsSection['highlights'] as Map<String, dynamic>).entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade400, size: 16.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
            ],

            // Nutritional Info (if extracted)
            if (nutritionalInfo != null && nutritionalInfo.isNotEmpty) ...[
              Text(
                'Nutritional Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                nutritionalInfo, // From Firestore
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // Seller Information
            if (sellerInfoSection != null) ...[
              Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              _buildInfoRow('Seller Name', sellerName), // From Firestore
              _buildInfoRow('Source of Origin', sellerInfoSection['sourceOfOrigin'] as String?),
              _buildInfoRow('FSSAI', sellerInfoSection['fssai'] as String?),
              _buildInfoRow('Address', sellerInfoSection['address'] as String?),
              _buildInfoRow('Customer Care', sellerInfoSection['customerCare'] as String?),
              _buildInfoRow('Email', sellerInfoSection['email'] as String?),
              _buildInfoRow('Certifications', sellerInfoSection['certifications'] as String?),
              SizedBox(height: 20.h),
            ],

            // Additional Info (Category, Subcategory, SKU, Tags etc.)
            if (additionalInfo != null) ...[
              Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              _buildInfoRow('Category', additionalInfo['category'] as String?), // From Firestore
              _buildInfoRow('Subcategory', additionalInfo['subCategory'] as String?), // From Firestore
              _buildInfoRow('SKU', productSku), // From Firestore
              _buildInfoRow('Product Type', productType), // From Firestore
              if (productTags.isNotEmpty)
                _buildInfoRow('Tags', productTags.join(', ')), // From Firestore
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods for loading and error states are unchanged and defined below _buildProductDetailsContent
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShimmerLoader(
          child: Container(
            width: 120.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          ShimmerLoader(
            child: Container(
              height: 250.h,
              width: double.infinity,
              margin: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Name Placeholder
          ShimmerLoader(
            child: Container(
              height: 24.h,
              width: 200.w,
              margin: EdgeInsets.symmetric(horizontal: 16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Price Placeholder
          ShimmerLoader(
            child: Container(
              height: 18.h,
              width: 100.w,
              margin: EdgeInsets.symmetric(horizontal: 16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Description Placeholder
          ShimmerLoader(
            child: Container(
              height: 100.h,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Error',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.r, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? 'Failed to load product details.',
                style: TextStyle(fontSize: 16.sp, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              Text(
                'Please check your internet connection or try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for info rows in seller/additional sections
  Widget _buildInfoRow(String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w, // Align titles
            child: Text(
              '$title:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}