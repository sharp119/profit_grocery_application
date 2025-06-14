import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BlocProvider
import 'package:profit_grocery_application/services/service_locator.dart' as sl; // Import service_locator.dart with alias

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart'; // Needed for Address type if used in args
import '../../presentation/pages/authentication/otp_verification_page.dart';
import '../../presentation/pages/authentication/phone_entry_page.dart';
import '../../presentation/pages/authentication/splash_screen.dart';
import '../../presentation/pages/authentication/user_registration_page.dart';

import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/orders/order_details_page.dart'; // NEW: Import OrderDetailsPage
// Removed `import '../../domain/entities/order.dart';` as it's not directly used here, only for type hinting
import '../../presentation/pages/coupon/coupon_page.dart';
import '../../presentation/pages/profile/addresses_page.dart';
import '../../presentation/pages/profile/address_form_page.dart';
import '../../presentation/pages/profile/profile_edit_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/main_navigation.dart';
import '../../presentation/pages/profile/developer_menu_page.dart';
import '../../presentation/pages/test/image_test_page.dart';
import '../../presentation/pages/test/product_card_test_page.dart';
import '../../presentation/pages/category_products/category_products_page.dart';
import '../../presentation/pages/home/bestseller_example.dart';

import '../../presentation/blocs/orders/orders_bloc.dart'; // NEW: Import OrdersBloc

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Authentication routes
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppConstants.loginRoute: // This might be phoneEntryRoute in latest AppConstants
        return MaterialPageRoute(builder: (_) => const PhoneEntryPage());

      case AppConstants.otpVerificationRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            phoneNumber: args['phoneNumber'],
            requestId: args['requestId'], // or verificationId depending on your latest Auth Bloc
          ),
        );

      // Home and main navigation routes
      case AppConstants.homeRoute: // This typically leads to MainNavigation in your setup
        return MaterialPageRoute(builder: (_) => const MainNavigation());

      // Category product routes
      case AppConstants.firestoreCategoryProductsRoute: // This might be categoryProductsRoute in latest AppConstants
        final categoryId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CategoryProductsPage(categoryId: categoryId),
        );

      // Profile routes
      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case AppConstants.profileEditRoute:
        return MaterialPageRoute(builder: (_) => const ProfileEditPage());

      case AppConstants.addressesRoute:
        return MaterialPageRoute(builder: (_) => const AddressesPage());

      case AppConstants.addAddressRoute: // This might be addressFormRoute in latest AppConstants
        return MaterialPageRoute(
          builder: (_) => const AddressFormPage(isEditing: false),
        );

      case AppConstants.editAddressRoute: // This might be addressFormRoute in latest AppConstants
        final address = settings.arguments as Address; // Requires `import '../../domain/entities/user.dart';`
        return MaterialPageRoute(
          builder: (_) => AddressFormPage(
            address: address,
            isEditing: true,
          ),
        );

      // Cart and checkout routes
      case AppConstants.cartRoute:
        // Cart functionality not implemented yet.
        // In the full project, this should be a BlocProvider for CartPage
        return MaterialPageRoute(
          builder: (_) => Scaffold( // Placeholder for unimplemented cart
            appBar: AppBar(title: const Text('Cart')),
            body: const Center(
              child: Text(
                'Cart functionality coming soon!',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        );

      // case AppConstants.checkoutRoute:
      //   return MaterialPageRoute(builder: (_) => const CheckoutPage());

      // case AppConstants.addressSelectionRoute:
      //   final args = settings.arguments as Map<String, dynamic>;
      //   return MaterialPageRoute(
      //     builder: (_) => AddressSelectionPage(
      //       onAddressSelected: args['onAddressSelected'],
      //       initialAddress: args['initialAddress'],
      //     ),
      //   );

      // Order routes
      case AppConstants.ordersRoute:
        // No initialTab needed in OrdersPage now
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl.sl<OrdersBloc>(), // Provide OrdersBloc using service locator
            child: const OrdersPage(), // No initialTab needed
          ),
        );

      case AppConstants.orderDetailsRoute: // NEW: Handle OrderDetailsRoute
        final orderId = settings.arguments as String; // Assuming orderId is passed as String
        return MaterialPageRoute(
          builder: (_) => OrderDetailsPage(orderId: orderId),
        );

      // Coupon route
      case AppConstants.couponRoute:
        final deepLinkCoupon = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CouponPage(deepLinkCoupon: deepLinkCoupon),
        );

      // User registration route
      case AppConstants.registerRoute: // This might be userRegistrationRoute in latest AppConstants
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

     
      // case AppConstants.bestsellerExampleRoute: // Keep uncommented if used, otherwise comment
      //   return MaterialPageRoute(builder: (_) => const BestsellerExamplePage());

      // Default - route not found
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Error: No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}