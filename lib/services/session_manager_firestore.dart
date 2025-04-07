import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/auth_model.dart';
import 'logging_service.dart';
import 'session_manager_interface.dart';

/// Manages user sessions with secure token generation, tracking, and validation using Firestore
class SessionManagerFirestore implements ISessionManager {
  // Singleton pattern
  static final SessionManagerFirestore _instance = SessionManagerFirestore._internal();
  factory SessionManagerFirestore() => _instance;
  SessionManagerFirestore._internal();

  // Dependencies will be initialized via setters
  SharedPreferences? _sharedPreferences;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  
  /// Set the SharedPreferences dependency
  void setSharedPreferences(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
  }
  
  /// Set the FirebaseFirestore dependency
  void setFirestore(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  // Collection references
  late final CollectionReference<Map<String, dynamic>> _sessionsCollection;

  // Constants
  static const String _sessionPrefKey = 'user_session';
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionCreatedKey = 'session_created';
  static const String _sessionExpiresKey = 'session_expires';
  static const String _sessionUserIdKey = 'session_user_id';

  /// Initialize the session manager with dependencies
  @override
  Future<void> init() async {
    // This is a no-op if already called with the right params
    if (_isInitialized) return;
    
    // If dependencies aren't set, this is an error
    if (_sharedPreferences == null || _firestore == null) {
      throw Exception('SessionManagerFirestore: Must set dependencies before calling init()');
    }
    
    _sessionsCollection = _firestore!.collection('sessions');
    _isInitialized = true;
    
    LoggingService.logFirestore('SessionManagerFirestore: Initialized');
    
    try {
      // Check and clean any expired sessions in SharedPreferences
      await _cleanupExpiredSession();
    } catch (e) {
      // Just log the error, don't fail initialization
      LoggingService.logError('SessionManagerFirestore', 'Error during expired session cleanup: ${e.toString()}');
    }
  }
  
  /// Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      throw Exception('SessionManagerFirestore not initialized. Call init() first.');
    }
    
    if (_sharedPreferences == null || _firestore == null) {
      throw Exception('SessionManagerFirestore: Dependencies not set. Call setSharedPreferences() and setFirestore() first.');
    }
  }

  /// Create a new session for a user with maximum security
  Future<UserSession> createSession(String userId) async {
    await _ensureInitialized();
    try {
      // Generate a secure session token (with cryptographic security)
      final sessionToken = _generateSecureToken(userId);
      
      // Get current timestamp
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: AppConstants.sessionTimeoutMinutes));
      
      // Create device info
      final deviceInfo = _getDeviceInfo();
      
      // Create session model
      final session = UserSession(
        userId: userId,
        token: sessionToken,
        createdAt: now,
        expiresAt: expiresAt,
        lastActive: now,
        deviceInfo: deviceInfo,
      );
      
      // 1. Save compact session data to SharedPreferences
      await _saveSessionToPreferences(session);
      
      // 2. Save complete session data to Firestore
      await _saveSessionToFirestore(userId, session);
      
      LoggingService.logFirestore('SessionManagerFirestore: Created new session for user $userId');
      
      return session;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error creating session', e.toString());
      throw Exception('Failed to create session: $e');
    }
  }
  
  /// Save session to SharedPreferences
  Future<void> _saveSessionToPreferences(UserSession session) async {
    // Save full session data as JSON
    await _sharedPreferences?.setString(_sessionPrefKey, jsonEncode(session.toJson()));
    
    // Also save key elements separately for quick access
    await _sharedPreferences?.setString(_sessionTokenKey, session.token);
    await _sharedPreferences?.setString(_sessionUserIdKey, session.userId);
    await _sharedPreferences?.setString(_sessionCreatedKey, session.createdAt.toIso8601String());
    await _sharedPreferences?.setString(_sessionExpiresKey, session.expiresAt.toIso8601String());
  }

  /// Validate a session and return if it's valid
  Future<bool> validateSession(String userId) async {
    try {
      await _ensureInitialized();
      
      // 1. First check if we have a userId
      if (userId.isEmpty) {
        LoggingService.logFirestore('SessionManagerFirestore: Empty userId provided for validation');
        return false;
      }
      
      // 2. Check local session
      final localValid = await _isLocalSessionValid(userId);
      if (!localValid) {
        LoggingService.logFirestore('SessionManagerFirestore: Local session validation failed for user $userId');
        return false;
      }
      
      // 3. Verify with Firestore for cross-device validation (with timeout protection)
      bool firestoreValid = false;
      try {
        firestoreValid = await _verifySessionInFirestore(userId);
      } catch (e) {
        // If Firestore validation fails, still consider session valid if local is valid
        // This allows the app to work offline if needed
        LoggingService.logError('SessionManagerFirestore', 'Firestore validation failed, using local validation: ${e.toString()}');
        return true; // Trust local validation if Firestore is unavailable
      }
      
      return firestoreValid;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error validating session', e.toString());
      return false;
    }
  }
  
  /// Check if the local session is valid
  Future<bool> _isLocalSessionValid(String userId) async {
    // Get session details from SharedPreferences
    final sessionJson = _sharedPreferences?.getString(_sessionPrefKey);
    final storedUserId = _sharedPreferences?.getString(_sessionUserIdKey);
    
    // Basic validation checks
    if (sessionJson == null || storedUserId != userId) {
      return false;
    }
    
    try {
      // Parse the expiration date
      final expiresAtString = _sharedPreferences?.getString(_sessionExpiresKey);
      if (expiresAtString == null) return false;
      
      final expiresAt = DateTime.parse(expiresAtString);
      
      // Check if session is expired
      if (DateTime.now().isAfter(expiresAt)) {
        LoggingService.logFirestore('SessionManagerFirestore: Local session expired for user $userId');
        await _cleanupExpiredSession();
        return false;
      }
      
      return true;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error checking local session', e.toString());
      return false;
    }
  }
  
  /// Verify the session in Firestore
  Future<bool> _verifySessionInFirestore(String userId) async {
    try {
      // Get the local token for comparison
      final localToken = _sharedPreferences?.getString(_sessionTokenKey);
      if (localToken == null) return false;
      
      // Get the session from Firestore
      final sessionDoc = await _sessionsCollection.doc(userId).get();
      
      if (!sessionDoc.exists) {
        LoggingService.logFirestore('SessionManagerFirestore: No session found in Firestore for user $userId');
        return false;
      }
      
      // Convert document to Map
      final sessionData = sessionDoc.data()!;
      
      // Verify token
      if (sessionData['token'] != localToken) {
        LoggingService.logFirestore('SessionManagerFirestore: Token mismatch for user $userId');
        return false;
      }
      
      // Check expiration
      final expiresAt = (sessionData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        LoggingService.logFirestore('SessionManagerFirestore: Firestore session expired for user $userId');
        return false;
      }
      
      // Update last active timestamp
      await _updateLastActive(userId);
      
      return true;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error verifying session in Firestore', e.toString());
      return false;
    }
  }

  /// Invalidate a session (logout)
  Future<void> invalidateSession(String userId) async {
    await _ensureInitialized();
    try {
      // 1. Remove from SharedPreferences
      await _sharedPreferences?.remove(_sessionPrefKey);
      await _sharedPreferences?.remove(_sessionTokenKey);
      await _sharedPreferences?.remove(_sessionCreatedKey);
      await _sharedPreferences?.remove(_sessionExpiresKey);
      await _sharedPreferences?.remove(_sessionUserIdKey);
      
      // 2. Remove from Firestore
      await _sessionsCollection.doc(userId).delete();
      
      LoggingService.logFirestore('SessionManagerFirestore: Invalidated session for user $userId');
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error invalidating session', e.toString());
      // Still consider the session invalidated even if Firestore removal fails
    }
  }

  /// Check if a user has an active session
  Future<bool> hasActiveSession() async {
    await _ensureInitialized();
    
    // Check for both session user ID and auth user ID
    final sessionUserId = _sharedPreferences?.getString(_sessionUserIdKey);
    final authUserId = _sharedPreferences?.getString(AppConstants.userTokenKey);
    
    LoggingService.logFirestore('SessionManagerFirestore: Checking for active session: sessionUserId=$sessionUserId, authUserId=$authUserId');
    
    if (sessionUserId == null && authUserId == null) {
      LoggingService.logFirestore('SessionManagerFirestore: No user ID found in preferences');
      return false;
    }
    
    final userId = sessionUserId ?? authUserId!;
    
    // Check if we have the basic session data
    final hasSessionData = _sharedPreferences?.containsKey(_sessionPrefKey) ?? false;
    final hasSessionToken = _sharedPreferences?.containsKey(_sessionTokenKey) ?? false;
    final authCompleted = _sharedPreferences?.getBool(AppConstants.authCompletedKey) ?? false;
    
    LoggingService.logFirestore('SessionManagerFirestore: Session data check: hasSessionData=$hasSessionData, hasSessionToken=$hasSessionToken, authCompleted=$authCompleted');
    
    if (!hasSessionData || !hasSessionToken) {
      // If we have authUserId but no session data, try to create a new session
      if (authCompleted && authUserId != null) {
        try {
          LoggingService.logFirestore('SessionManagerFirestore: Attempting to create new session for existing user');
          await createSession(authUserId);
          return true;
        } catch (e) {
          LoggingService.logError('SessionManagerFirestore', 'Failed to create new session for existing user: $e');
          return false;
        }
      }
      return false;
    }
    
    // Validate existing session
    try {
      final isValid = await validateSession(userId);
      
      if (!isValid && authCompleted && authUserId != null) {
        // If invalid but the user was previously authenticated, try to create a new session
        try {
          LoggingService.logFirestore('SessionManagerFirestore: Session invalid, creating new session for authenticated user');
          await createSession(authUserId);
          return true;
        } catch (e) {
          LoggingService.logError('SessionManagerFirestore', 'Failed to create new session after validation failed: $e');
          return false;
        }
      }
      
      return isValid;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore', 'Error validating session: $e');
      return false;
    }
  }

  /// Extend the current session
  Future<bool> extendSession(String userId) async {
    await _ensureInitialized();
    try {
      // Get current session token
      final token = _sharedPreferences?.getString(_sessionTokenKey);
      if (token == null) {
        return false;
      }
      
      // Check if it's valid first
      if (!await validateSession(userId)) {
        return false;
      }
      
      // Get the session JSON string
      final sessionJson = _sharedPreferences?.getString(_sessionPrefKey);
      if (sessionJson == null) {
        return false;
      }
      
      // Parse session data
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      
      // Update expiration time
      final now = DateTime.now();
      final newExpiresAt = now.add(Duration(minutes: AppConstants.sessionTimeoutMinutes));
      
      // Update session data
      sessionData['expiresAt'] = newExpiresAt.toIso8601String();
      sessionData['lastActive'] = now.toIso8601String();
      
      // Save to SharedPreferences
      await _sharedPreferences?.setString(_sessionPrefKey, jsonEncode(sessionData));
      await _sharedPreferences?.setString(_sessionExpiresKey, newExpiresAt.toIso8601String());
      
      // Update in Firestore
      await _sessionsCollection.doc(userId).update({
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'lastActive': Timestamp.fromDate(now),
      });
      
      LoggingService.logFirestore('SessionManagerFirestore: Extended session for user $userId');
      return true;
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error extending session', e.toString());
      return false;
    }
  }

  /// Get the current session token
  String? getSessionToken() {
    return _sharedPreferences?.getString(_sessionTokenKey);
  }
  
  /// Get the current user ID from session
  String? getCurrentUserId() {
    return _sharedPreferences?.getString(_sessionUserIdKey);
  }
  
  /// Cleanup any expired session in SharedPreferences
  Future<void> _cleanupExpiredSession() async {
    try {
      final expiresAtString = _sharedPreferences?.getString(_sessionExpiresKey);
      
      if (expiresAtString != null) {
        final expiresAt = DateTime.parse(expiresAtString);
        
        if (DateTime.now().isAfter(expiresAt)) {
          // Session is expired, clean it up
          await _sharedPreferences?.remove(_sessionPrefKey);
          await _sharedPreferences?.remove(_sessionTokenKey);
          await _sharedPreferences?.remove(_sessionCreatedKey);
          await _sharedPreferences?.remove(_sessionExpiresKey);
          await _sharedPreferences?.remove(_sessionUserIdKey);
          
          LoggingService.logFirestore('SessionManagerFirestore: Cleaned up expired local session');
        }
      }
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error cleaning up expired session', e.toString());
    }
  }

  // Private helper methods

  /// Generate a cryptographically secure token
  String _generateSecureToken(String userId) {
    final random = Random.secure();
    
    // Generate a secure random salt (32 bytes)
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final salt = base64Url.encode(values);
    
    // Add uniqueness with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Add a nonce for additional security
    final nonce = List<int>.generate(16, (i) => random.nextInt(256));
    final nonceStr = base64Url.encode(nonce);
    
    // Combine all factors with user ID for a unique token
    final data = utf8.encode('$userId:$salt:$timestamp:$nonceStr');
    
    // Use SHA-256 hash for secure token generation
    final hash = sha256.convert(data);
    
    return hash.toString();
  }

  /// Save session data to Firestore
  Future<void> _saveSessionToFirestore(String userId, UserSession session) async {
    try {
      await _sessionsCollection.doc(userId).set({
        'userId': session.userId,
        'token': session.token,
        'createdAt': Timestamp.fromDate(session.createdAt),
        'expiresAt': Timestamp.fromDate(session.expiresAt),
        'lastActive': Timestamp.fromDate(session.lastActive),
        'deviceInfo': session.deviceInfo,
      });
    } catch (e) {
      LoggingService.logError('SessionManagerFirestore: Error saving session to Firestore', e.toString());
      throw e;
    }
  }

  /// Update the last active timestamp
  Future<void> _updateLastActive(String userId) async {
    try {
      final now = DateTime.now();
      
      // Update in SharedPreferences
      final sessionJson = _sharedPreferences?.getString(_sessionPrefKey);
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        sessionData['lastActive'] = now.toIso8601String();
        await _sharedPreferences?.setString(_sessionPrefKey, jsonEncode(sessionData));
      }
      
      // Update in Firestore
      await _sessionsCollection.doc(userId).update({
        'lastActive': Timestamp.fromDate(now),
      });
    } catch (e) {
      // Log but don't throw - this is a non-critical operation
      LoggingService.logError('SessionManagerFirestore: Error updating last active time', e.toString());
    }
  }

  /// Get detailed device information for security tracking
  Map<String, dynamic> _getDeviceInfo() {
    // In a real app, you would use a device info plugin to get more details
    return {
      'appVersion': AppConstants.appVersion,
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': Random().nextInt(1000000).toString(), // Placeholder
      'osVersion': 'Unknown', // Would be populated with real data
    };
  }
}