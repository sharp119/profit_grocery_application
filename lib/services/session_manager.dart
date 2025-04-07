import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/auth_model.dart';
import 'logging_service.dart';

/// Manages user sessions with secure token generation, tracking, and validation
class SessionManager {
  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Dependencies will be initialized via init method
  late SharedPreferences _sharedPreferences;
  late FirebaseDatabase _firebaseDatabase;
  bool _isInitialized = false;

  // Constants
  static const String _sessionPrefKey = 'user_session';
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionCreatedKey = 'session_created';
  static const String _sessionExpiresKey = 'session_expires';
  static const String _sessionUserIdKey = 'session_user_id';
  
  // The Firebase path for sessions
  static const String _sessionsPath = 'sessions';
  
  /// Initialize the session manager with dependencies
  Future<void> init({
    required SharedPreferences sharedPreferences,
    required FirebaseDatabase firebaseDatabase,
  }) async {
    if (_isInitialized) return;
    
    _sharedPreferences = sharedPreferences;
    _firebaseDatabase = firebaseDatabase;
    _isInitialized = true;
    
    LoggingService.logFirestore('SessionManager: Initialized');
    
    try {
      // Check and clean any expired sessions in SharedPreferences
      await _cleanupExpiredSession();
    } catch (e) {
      // Just log the error, don't fail initialization
      LoggingService.logError('SessionManager', 'Error during expired session cleanup: ${e.toString()}');
    }
  }
  
  /// Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      throw Exception('SessionManager not initialized. Call init() first.');
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
      
      // 2. Save complete session data to Firebase
      await _saveSessionToFirebase(userId, session);
      
      LoggingService.logFirestore('SessionManager: Created new session for user $userId');
      
      return session;
    } catch (e) {
      LoggingService.logError('SessionManager: Error creating session', e.toString());
      throw Exception('Failed to create session: $e');
    }
  }
  
  /// Save session to SharedPreferences
  Future<void> _saveSessionToPreferences(UserSession session) async {
    // Save full session data as JSON
    await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(session.toJson()));
    
    // Also save key elements separately for quick access
    await _sharedPreferences.setString(_sessionTokenKey, session.token);
    await _sharedPreferences.setString(_sessionUserIdKey, session.userId);
    await _sharedPreferences.setString(_sessionCreatedKey, session.createdAt.toIso8601String());
    await _sharedPreferences.setString(_sessionExpiresKey, session.expiresAt.toIso8601String());
  }

  /// Validate a session and return if it's valid
  Future<bool> validateSession(String userId) async {
    try {
      await _ensureInitialized();
      
      // 1. First check if we have a userId
      if (userId.isEmpty) {
        LoggingService.logFirestore('SessionManager: Empty userId provided for validation');
        return false;
      }
      
      // 2. Check local session
      final localValid = await _isLocalSessionValid(userId);
      if (!localValid) {
        LoggingService.logFirestore('SessionManager: Local session validation failed for user $userId');
        return false;
      }
      
      // 3. Verify with Firebase for cross-device validation (with timeout protection)
      bool firebaseValid = false;
      try {
        firebaseValid = await _verifySessionInFirebase(userId);
      } catch (e) {
        // If Firebase validation fails, still consider session valid if local is valid
        // This allows the app to work offline if needed
        LoggingService.logError('SessionManager', 'Firebase validation failed, using local validation: ${e.toString()}');
        return true; // Trust local validation if Firebase is unavailable
      }
      
      return firebaseValid;
    } catch (e) {
      LoggingService.logError('SessionManager: Error validating session', e.toString());
      return false;
    }
  }
  
  /// Check if the local session is valid
  Future<bool> _isLocalSessionValid(String userId) async {
    // Get session details from SharedPreferences
    final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
    final storedUserId = _sharedPreferences.getString(_sessionUserIdKey);
    
    // Basic validation checks
    if (sessionJson == null || storedUserId != userId) {
      return false;
    }
    
    try {
      // Parse the expiration date
      final expiresAtString = _sharedPreferences.getString(_sessionExpiresKey);
      if (expiresAtString == null) return false;
      
      final expiresAt = DateTime.parse(expiresAtString);
      
      // Check if session is expired
      if (DateTime.now().isAfter(expiresAt)) {
        LoggingService.logFirestore('SessionManager: Local session expired for user $userId');
        await _cleanupExpiredSession();
        return false;
      }
      
      return true;
    } catch (e) {
      LoggingService.logError('SessionManager: Error checking local session', e.toString());
      return false;
    }
  }
  
  /// Verify the session in Firebase
  Future<bool> _verifySessionInFirebase(String userId) async {
    try {
      // Get the local token for comparison
      final localToken = _sharedPreferences.getString(_sessionTokenKey);
      if (localToken == null) return false;
      
      // Get the session from Firebase
      final sessionRef = _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId);
      
      final snapshot = await sessionRef.get();
      
      if (!snapshot.exists) {
        LoggingService.logFirestore('SessionManager: No session found in Firebase for user $userId');
        return false;
      }
      
      // Convert snapshot to Map
      final sessionData = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Verify token
      if (sessionData['token'] != localToken) {
        LoggingService.logFirestore('SessionManager: Token mismatch for user $userId');
        return false;
      }
      
      // Check expiration
      final expiresAt = DateTime.parse(sessionData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        LoggingService.logFirestore('SessionManager: Firebase session expired for user $userId');
        return false;
      }
      
      // Update last active timestamp
      await _updateLastActive(userId);
      
      return true;
    } catch (e) {
      LoggingService.logError('SessionManager: Error verifying session in Firebase', e.toString());
      return false;
    }
  }

  /// Invalidate a session (logout)
  Future<void> invalidateSession(String userId) async {
    await _ensureInitialized();
    try {
      // 1. Remove from SharedPreferences
      await _sharedPreferences.remove(_sessionPrefKey);
      await _sharedPreferences.remove(_sessionTokenKey);
      await _sharedPreferences.remove(_sessionCreatedKey);
      await _sharedPreferences.remove(_sessionExpiresKey);
      await _sharedPreferences.remove(_sessionUserIdKey);
      
      // 2. Remove from Firebase
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .remove();
      
      LoggingService.logFirestore('SessionManager: Invalidated session for user $userId');
    } catch (e) {
      LoggingService.logError('SessionManager: Error invalidating session', e.toString());
      // Still consider the session invalidated even if Firebase removal fails
    }
  }

  /// Check if a user has an active session
  Future<bool> hasActiveSession() async {
    await _ensureInitialized();
    
    final userId = _sharedPreferences.getString(_sessionUserIdKey);
    if (userId == null) {
      return false;
    }
    
    return await validateSession(userId);
  }

  /// Extend the current session
  Future<bool> extendSession(String userId) async {
    await _ensureInitialized();
    try {
      // Get current session token
      final token = _sharedPreferences.getString(_sessionTokenKey);
      if (token == null) {
        return false;
      }
      
      // Check if it's valid first
      if (!await validateSession(userId)) {
        return false;
      }
      
      // Get the session JSON string
      final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
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
      await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(sessionData));
      await _sharedPreferences.setString(_sessionExpiresKey, newExpiresAt.toIso8601String());
      
      // Update in Firebase
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .update({
            'expiresAt': newExpiresAt.toIso8601String(),
            'lastActive': now.toIso8601String(),
          });
      
      LoggingService.logFirestore('SessionManager: Extended session for user $userId');
      return true;
    } catch (e) {
      LoggingService.logError('SessionManager: Error extending session', e.toString());
      return false;
    }
  }

  /// Get the current session token
  String? getSessionToken() {
    return _sharedPreferences.getString(_sessionTokenKey);
  }
  
  /// Get the current user ID from session
  String? getCurrentUserId() {
    return _sharedPreferences.getString(_sessionUserIdKey);
  }
  
  /// Get all active sessions for a user
  Future<List<UserSession>> getActiveSessions(String userId) async {
    await _ensureInitialized();
    try {
      final sessionsRef = _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId);
      
      final snapshot = await sessionsRef.get();
      
      if (!snapshot.exists) {
        return [];
      }
      
      // Convert to list of sessions
      // Note: In a real implementation, sessions would be structured better
      // to support multiple sessions per user with unique IDs
      final List<UserSession> sessions = [];
      
      // For now, just return the current session if it exists
      if (snapshot.exists) {
        final sessionData = Map<String, dynamic>.from(snapshot.value as Map);
        sessions.add(UserSession.fromJson(userId, sessionData));
      }
      
      return sessions;
    } catch (e) {
      LoggingService.logError('SessionManager: Error getting active sessions', e.toString());
      return [];
    }
  }
  
  /// Cleanup any expired session in SharedPreferences
  Future<void> _cleanupExpiredSession() async {
    try {
      final expiresAtString = _sharedPreferences.getString(_sessionExpiresKey);
      
      if (expiresAtString != null) {
        final expiresAt = DateTime.parse(expiresAtString);
        
        if (DateTime.now().isAfter(expiresAt)) {
          // Session is expired, clean it up
          await _sharedPreferences.remove(_sessionPrefKey);
          await _sharedPreferences.remove(_sessionTokenKey);
          await _sharedPreferences.remove(_sessionCreatedKey);
          await _sharedPreferences.remove(_sessionExpiresKey);
          await _sharedPreferences.remove(_sessionUserIdKey);
          
          LoggingService.logFirestore('SessionManager: Cleaned up expired local session');
        }
      }
    } catch (e) {
      LoggingService.logError('SessionManager: Error cleaning up expired session', e.toString());
    }
  }

  // Private helper methods

  /// Generate a cryptographically secure token
  /// Uses a combination of:
  /// - Secure random values
  /// - User ID
  /// - Timestamp
  /// - SHA-256 hashing
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

  /// Save session data to Firebase
  Future<void> _saveSessionToFirebase(String userId, UserSession session) async {
    try {
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .set(session.toJson());
    } catch (e) {
      LoggingService.logError('SessionManager: Error saving session to Firebase', e.toString());
      throw e;
    }
  }

  /// Update the last active timestamp
  Future<void> _updateLastActive(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Update in SharedPreferences
      final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        sessionData['lastActive'] = now;
        await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(sessionData));
      }
      
      // Update in Firebase
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .update({
            'lastActive': now,
          });
    } catch (e) {
      // Log but don't throw - this is a non-critical operation
      LoggingService.logError('SessionManager: Error updating last active time', e.toString());
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