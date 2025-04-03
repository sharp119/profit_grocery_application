import 'dart:developer' as developer;

class LoggingService {
  static void logFirestore(String message) {
    developer.log(message, name: 'FIRESTORE');
    print('📝 FIRESTORE: $message');
  }

  static void logError(String message, dynamic error) {
    developer.log('$message: $error', name: 'ERROR');
    print('❌ ERROR: $message: $error');
  }
}
