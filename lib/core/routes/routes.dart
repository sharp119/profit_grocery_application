import 'package:flutter/material.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';

import '../../presentation/pages/profile/developer_menu_page.dart';
import '../../presentation/pages/test/image_test_page.dart';
import '../../presentation/pages/test/product_card_test_page.dart';

/// Route generator for the app
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if available
    final args = settings.arguments;

    switch (settings.name) {
      // Developer routes
      case AppConstants.developerMenuRoute:
        return MaterialPageRoute(builder: (_) => const DeveloperMenuPage());
      
      case AppConstants.imageTestRoute:
        return MaterialPageRoute(builder: (_) => const ImageTestPage());
      
      case AppConstants.productCardTestRoute:
        return MaterialPageRoute(builder: (_) => const ProductCardTestPage());
        
      // Default case - route not found
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
