import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// Service to handle cart initialization at app startup
class CartInitializer {
  final CartBloc cartBloc;
  final SharedPreferences sharedPreferences;
  bool _isInitializing = false;
  bool _isInitialized = false;

  CartInitializer({
    required this.cartBloc,
    required this.sharedPreferences,
  });

  /// Initialize the cart at app startup - with safety lock
  Future<void> initialize() async {
    // Avoid duplicate initializations
    if (_isInitializing || _isInitialized) {
      CartLogger.info('CART_INIT', 'Cart already initialized or initializing, skipping');
      return;
    }

    _isInitializing = true;
    CartLogger.log('CART_INIT', 'Initializing cart at app startup');
    
    try {
      // Check if user is logged in
      final userId = sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        CartLogger.info('CART_INIT', 'User is logged in: $userId, loading cart');
        
        // Add a small delay to ensure Firebase is fully initialized
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Dispatch the LoadCart event to the CartBloc
        cartBloc.add(const LoadCart());
        
        CartLogger.success('CART_INIT', 'Cart initialization triggered successfully');
      } else {
        CartLogger.info('CART_INIT', 'No user logged in, skipping cart initialization');
      }
      
      _isInitialized = true;
    } catch (e) {
      CartLogger.error('CART_INIT', 'Error initializing cart', e);
    } finally {
      _isInitializing = false;
    }
  }
}