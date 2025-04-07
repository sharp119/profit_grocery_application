import '../data/models/auth_model.dart';

/// Common interface for session managers (both Firestore and RTDB implementations)
abstract class ISessionManager {
  /// Initialize the session manager with dependencies
  Future<void> init();

  /// Create a new session for a user with maximum security
  Future<UserSession> createSession(String userId);

  /// Validate a session and return if it's valid
  Future<bool> validateSession(String userId);

  /// Invalidate a session (logout)
  Future<void> invalidateSession(String userId);

  /// Check if a user has an active session
  Future<bool> hasActiveSession();

  /// Extend the current session
  Future<bool> extendSession(String userId);

  /// Get the current session token
  String? getSessionToken();
  
  /// Get the current user ID from session
  String? getCurrentUserId();
}