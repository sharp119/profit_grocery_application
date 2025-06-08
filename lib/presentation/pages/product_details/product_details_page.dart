import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:profit_grocery_application/domain/entities/product.dart'; // Product entity (for RTDB data)
import 'package:profit_grocery_application/presentation/widgets/product_details/product_hero_section.dart';
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart'; // Firestore service (for raw sections)
import 'package:profit_grocery_application/services/rtdb_product_service.dart'; // RTDB service (for dynamic Product)
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/presentation/widgets/buttons/add_button.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/loaders/shimmer_loader.dart';
import 'package:profit_grocery_application/services/logging_service.dart';
import 'package:profit_grocery_application/presentation/widgets/image_loader.dart';
import 'package:profit_grocery_application/presentation/widgets/product_details/product_description_section.dart'; // New Import
import 'package:profit_grocery_application/presentation/widgets/product_details/product_highlights_section.dart'; // New Import
import 'package:profit_grocery_application/presentation/widgets/product_details/product_nutritional_info_section.dart'; // New Import
import 'package:profit_grocery_application/presentation/widgets/product_details/product_seller_info_section.dart'; // New Import
import 'package:profit_grocery_application/presentation/widgets/product_details/product_additional_info_section.dart'; // New Import


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
            // Product Image Carousel (Hero Section Visual) and other header info
            ProductDetailHeroSection(
              productImages: productImages,
              pageController: _pageController,
              currentPage: _currentPage,
              onImagePageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBackgroundColor: itemBackgroundColorFromRTDB,
              dynamicHasDiscount: dynamicHasDiscount,
              dynamicDiscountValue: dynamicDiscountValue,
              dynamicDiscountType: dynamicDiscountType,
              productName: productName,
              productRating: productRating,
              productReviewCount: productReviewCount,
              productBrand: productBrand,
              productWeight: productWeight,
              productType: productType,
              displayPrice: displayPrice,
              showDiscountStrikethrough: showDiscountStrikethrough,
              displayMrp: displayMrp,
              displayInStock: displayInStock,
              productId: widget.productId,
            ),

            // Product Description Section
            ProductDescriptionSection(
              productDescription: productDescription,
            ),

            // Product Highlights Section
            ProductHighlightsSection(
              highlightsData: highlightsSection,
            ),

            // Nutritional Info Section
            ProductNutritionalInfoSection(
              nutritionalInfo: nutritionalInfo,
            ),

            // Seller Information Section
            ProductSellerInfoSection(
              sellerInfoData: sellerInfoSection,
              sellerName: sellerName,
            ),

            // Additional Info Section
            ProductAdditionalInfoSection(
              additionalInfoData: additionalInfo,
              productSku: productSku,
              productType: productType,
              productTags: productTags,
            ),
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
}