import 'dart:async';

import '../domain/entities/user.dart';

/// Interface defining the contract for UserService implementations
abstract class IUserService {
  /// Get a stream of user data
  Stream<User?> get userStream;

  /// Get the current user data (null if not logged in)
  User? getCurrentUser();

  /// Get the current user ID (null if not logged in)
  String? getCurrentUserId();

  /// Get the user's name (or null if not available)
  String? getUserName();

  /// Get the user's phone number (or null if not available)
  String? getUserPhone();

  /// Clear the current user data (logout)
  void clearCurrentUser();
  
  /// Check if the user is logged in
  bool isLoggedIn();
  
  /// Listen to user data changes
  StreamSubscription<User?> listenToUserChanges(void Function(User?) onUserChanged);
  
  /// Dispose the service
  void dispose();
}