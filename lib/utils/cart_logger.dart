import 'dart:developer' as developer;

class CartLogger {
  static void log(String tag, String message) {
    developer.log(
      '📝 $message',
      name: 'CART_$tag',
      time: DateTime.now(),
    );
  }
  
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '❌ $message',
      name: 'CART_ERROR_$tag',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void info(String tag, String message) {
    developer.log(
      '📊 $message',
      name: 'CART_INFO_$tag',
      time: DateTime.now(),
    );
  }
  
  static void success(String tag, String message) {
    developer.log(
      '✅ $message',
      name: 'CART_SUCCESS_$tag',
      time: DateTime.now(),
    );
  }
}
