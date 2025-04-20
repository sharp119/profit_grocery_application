import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../../presentation/pages/authentication/otp_verification_page.dart';
import '../../presentation/pages/authentication/phone_entry_page.dart';
import '../../presentation/pages/authentication/splash_screen.dart';
import '../../presentation/pages/authentication/user_registration_page.dart';
import '../../presentation/pages/cart/cart_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/checkout/address_selection_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/orders/order_details_page.dart';
import '../../domain/entities/order.dart';
import '../../presentation/pages/coupon/coupon_page.dart';
import '../../presentation/pages/profile/addresses_page.dart';
import '../../presentation/pages/profile/address_form_page.dart';
import '../../presentation/pages/profile/profile_edit_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/main_navigation.dart';
import '../../presentation/pages/profile/developer_menu_page.dart';
import '../../presentation/pages/test/image_test_page.dart';
import '../../presentation/pages/test/product_card_test_page.dart';
import '../../presentation/pages/category_products/firestore/firestore_category_products_page.dart';
import '../../presentation/pages/dev/firestore_sync_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Authentication routes
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const PhoneEntryPage());
      
      case AppConstants.otpVerificationRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            phoneNumber: args['phoneNumber'],
            requestId: args['requestId'],
          ),
        );
        
      // Home and main navigation routes
      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const MainNavigation());
        
      // Category product routes
      case AppConstants.firestoreCategoryProductsRoute:
        final categoryId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => FirestoreCategoryProductsPage(categoryId: categoryId),
        );
        
      // Profile routes
      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
        
      case AppConstants.profileEditRoute:
        return MaterialPageRoute(builder: (_) => const ProfileEditPage());
        
      case AppConstants.addressesRoute:
        return MaterialPageRoute(builder: (_) => const AddressesPage());
        
      case AppConstants.addAddressRoute:
        return MaterialPageRoute(
          builder: (_) => const AddressFormPage(isEditing: false),
        );
        
      case AppConstants.editAddressRoute:
        final address = settings.arguments as Address;
        return MaterialPageRoute(
          builder: (_) => AddressFormPage(
            address: address,
            isEditing: true,
          ),
        );
        
      // Cart and checkout routes
      case AppConstants.cartRoute:
        return MaterialPageRoute(builder: (_) => const CartPage());
        
      case AppConstants.checkoutRoute:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());
        
      case AppConstants.addressSelectionRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddressSelectionPage(
            onAddressSelected: args['onAddressSelected'],
            initialAddress: args['initialAddress'],
          ),
        );
        
      // Order routes
      case AppConstants.ordersRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => OrdersPage(
          initialTab: args != null ? args['initialTab'] ?? 0 : 0,
        ));
        
      case AppConstants.orderDetailsRoute:
        final order = settings.arguments as Order;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsPage(order: order),
        );
        
      // Coupon route
      case AppConstants.couponRoute:
        final deepLinkCoupon = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CouponPage(deepLinkCoupon: deepLinkCoupon),
        );
        
      // User registration route
      case AppConstants.registerRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => UserRegistrationPage(
            phoneNumber: args['phoneNumber'],
            isPreRegistration: args['isPreRegistration'] ?? false,
          ),
        );
      
      // Developer routes
      case AppConstants.developerMenuRoute:
        return MaterialPageRoute(builder: (_) => const DeveloperMenuPage());
      
      case AppConstants.imageTestRoute:
        return MaterialPageRoute(builder: (_) => const ImageTestPage());
      
      case AppConstants.productCardTestRoute:
        return MaterialPageRoute(builder: (_) => const ProductCardTestPage());
        
      case AppConstants.firestoreSyncRoute:
        return MaterialPageRoute(builder: (_) => const FirestoreSyncPage());
          
      // Default - route not found
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
