class AppConstants {
  // App Information
  static const String appName = 'ProfitGrocery';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart shopping, more savings';
  
  // API Endpoints
  static const String baseUrl = 'https://api.profitgrocery.com';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String couponsCollection = 'coupons';
  static const String cartsCollection = 'carts';
  
  // Remote Config Keys
  static const String featuredCategoriesKey = 'featured_categories';
  static const String appMaintenanceKey = 'app_maintenance';
  static const String minAppVersionKey = 'min_app_version';
  
  // Shared Preferences Keys
  static const String userTokenKey = 'user_token';
  static const String userPhoneKey = 'user_phone';
  static const String userCartKey = 'user_cart';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String firstLaunchKey = 'first_launch';
  static const String authCompletedKey = 'auth_completed'; // Added for improved auth persistence
  
  // Pagination
  static const int productsPerPage = 10;
  static const int ordersPerPage = 10;
  
  // Time Constants
  static const int otpExpiryMinutes = 10;
  static const int sessionTimeoutMinutes = 43200; // 30 days (60 * 24 * 30)
  
  // Currency Symbol
  static const String currencySymbol = '₹';
  
  // Default Values
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String otpVerificationRoute = '/otp-verification';
  static const String homeRoute = '/home';
  static const String categoryProductsRoute = '/category-products';
  static const String firestoreCategoryProductsRoute = '/firestore-category-products';
  static const String productDetailsRoute = '/product-details';
  static const String cartRoute = '/cart';
  static const String checkoutRoute = '/checkout';
  static const String addressSelectionRoute = '/checkout/address-selection';
  static const String orderSuccessRoute = '/order-success';
  static const String ordersRoute = '/orders';
  static const String orderDetailsRoute = '/order-details';
  static const String couponRoute = '/coupon';
  static const String settingsRoute = '/settings';
  
  // Profile Routes
  static const String profileRoute = '/profile';
  static const String profileEditRoute = '/profile/edit';
  static const String addressesRoute = '/profile/addresses';
  static const String addAddressRoute = '/profile/address/add';
  static const String editAddressRoute = '/profile/address/edit';
  static const String registerRoute = '/auth/register';
  
  // Developer Routes
  static const String developerMenuRoute = '/dev';  
  static const String imageTestRoute = '/dev/image-test';
  static const String productCardTestRoute = '/dev/product-card-test';
  static const String firestoreSyncRoute = '/dev/firestore-sync';
  static const String bestsellerExampleRoute = '/dev/bestseller-example';
  
  // Admin Routes
  static const String adminLoginRoute = '/admin/login';
  static const String adminDashboardRoute = '/admin/dashboard';
  static const String adminProductsRoute = '/admin/products';
  static const String adminOrdersRoute = '/admin/orders';
  static const String adminCouponsRoute = '/admin/coupons';
  static const String adminCustomersRoute = '/admin/customers';
  
  // Asset Paths
  static const String assetsImagesPath = 'assets/images/';
  static const String assetsCategoriesPath = 'assets/categories/';
  static const String assetsSubcategoriesPath = 'assets/subcategories/';
  static const String assetsProductsPath = 'assets/products/';
  static const String assetsCimgsPath = 'assets/cimgs/';
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String generalErrorMessage = 'Something went wrong. Please try again later.';
  static const String sessionExpiredMessage = 'Your session has expired. Please login again.';
  
  // Success Messages
  static const String orderSuccessMessage = 'Your order has been placed successfully!';
  static const String couponAppliedMessage = 'Coupon applied successfully!';
  
  // Category Types
  static const String regularCategoryType = 'regular';
  static const String storeCategoryType = 'store';
  static const String promotionalCategoryType = 'promotional';
  
  // Order Status
  static const String orderStatusNew = 'new';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';
  
  // Coupon Types
  static const String couponTypePercentage = 'percentage';
  static const String couponTypeFixedAmount = 'fixed';
  static const String couponTypeFreeProduct = 'free_product';
  static const String couponTypeConditional = 'conditional';

  static bool bestsellerRanked = false;

  static int bestsellerLimit = 4;
  
  AppConstants._(); // Private constructor to prevent instantiation
}