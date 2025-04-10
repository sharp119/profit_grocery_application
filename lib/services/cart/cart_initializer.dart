import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// Service to handle cart initialization at app startup
class CartInitializer {
  final CartBloc cartBloc;
  final SharedPreferences sharedPreferences;

  CartInitializer({
    required this.cartBloc,
    required this.sharedPreferences,
  });

  /// Initialize the cart at app startup
  Future<void> initialize() async {
    CartLogger.log('CART_INIT', 'Initializing cart at app startup');
    
    try {
      // Check if user is logged in
      final userId = sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        CartLogger.info('CART_INIT', 'User is logged in: $userId, loading cart');
        
        // Dispatch the LoadCart event to the CartBloc
        cartBloc.add(const LoadCart());
        
        CartLogger.success('CART_INIT', 'Cart initialization triggered successfully');
      } else {
        CartLogger.info('CART_INIT', 'No user logged in, skipping cart initialization');
      }
    } catch (e) {
      CartLogger.error('CART_INIT', 'Error initializing cart', e);
    }
  }
}