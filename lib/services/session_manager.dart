import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'logging_service.dart';

/// Manages user sessions with secure token handling
class SessionManager {
  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Dependencies will be initialized via init method
  late SharedPreferences _sharedPreferences;
  late FirebaseDatabase _firebaseDatabase;

  // Constants
  static const String _sessionPrefKey = 'user_session';
  static const String _sessionTokenKey = 'session_token';
  
  // The Firebase path for sessions
  static const String _sessionsPath = 'sessions';

  /// Initialize the session manager with dependencies
  Future<void> init({
    required SharedPreferences sharedPreferences,
    required FirebaseDatabase firebaseDatabase,
  }) async {
    _sharedPreferences = sharedPreferences;
    _firebaseDatabase = firebaseDatabase;
    
    // Set up a periodic task to refresh session if needed
    // This would be implemented in a real app using a background service
  }

  /// Create a new session for a user
  Future<String> createSession(String userId) async {
    try {
      // Generate a secure session token
      final sessionToken = _generateSecureToken(userId);
      
      // Get current timestamp
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: AppConstants.sessionTimeoutMinutes));
      
      // Create session data
      final sessionData = {
        'token': sessionToken,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'deviceInfo': _getDeviceInfo(),
        'lastActive': now.toIso8601String(),
      };
      
      // Save to SharedPreferences
      await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(sessionData));
      await _sharedPreferences.setString(_sessionTokenKey, sessionToken);
      
      // Save to Firebase for cross-device tracking
      await _saveSessionToFirebase(userId, sessionData);
      
      LoggingService.logFirestore('SessionManager: Created new session for user $userId');
      
      return sessionToken;
    } catch (e) {
      LoggingService.logError('SessionManager: Error creating session', e.toString());
      throw Exception('Failed to create session: $e');
    }
  }

  /// Validate a session
  Future<bool> validateSession(String userId) async {
    try {
      // Get session from SharedPreferences
      final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
      if (sessionJson == null) {
        return false;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(sessionData['expiresAt'] as String);
      
      // Check if session is expired
      if (DateTime.now().isAfter(expiresAt)) {
        LoggingService.logFirestore('SessionManager: Session expired for user $userId');
        await invalidateSession(userId);
        return false;
      }
      
      // Update last active timestamp
      await _updateLastActive(userId);
      
      return true;
    } catch (e) {
      LoggingService.logError('SessionManager: Error validating session', e.toString());
      return false;
    }
  }

  /// Invalidate a session (logout)
  Future<void> invalidateSession(String userId) async {
    try {
      // Remove from SharedPreferences
      await _sharedPreferences.remove(_sessionPrefKey);
      await _sharedPreferences.remove(_sessionTokenKey);
      
      // Remove from Firebase
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
    final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
    if (sessionJson == null) {
      return false;
    }
    
    try {
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(sessionData['expiresAt'] as String);
      
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      LoggingService.logError('SessionManager: Error checking active session', e.toString());
      return false;
    }
  }

  /// Extend the current session
  Future<bool> extendSession(String userId) async {
    try {
      // Get current session
      final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
      if (sessionJson == null) {
        return false;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      
      // Update expiration time
      final now = DateTime.now();
      final newExpiresAt = now.add(Duration(minutes: AppConstants.sessionTimeoutMinutes));
      
      sessionData['expiresAt'] = newExpiresAt.toIso8601String();
      sessionData['lastActive'] = now.toIso8601String();
      
      // Save to SharedPreferences
      await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(sessionData));
      
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

  // Private helper methods

  /// Generate a secure random token
  String _generateSecureToken(String userId) {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final salt = base64Url.encode(values);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Combine userId, salt and timestamp
    final data = utf8.encode('$userId:$salt:$timestamp');
    final hash = sha256.convert(data);
    
    return hash.toString();
  }

  /// Save session data to Firebase
  Future<void> _saveSessionToFirebase(String userId, Map<String, dynamic> sessionData) async {
    try {
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .set(sessionData);
    } catch (e) {
      LoggingService.logError('SessionManager: Error saving session to Firebase', e.toString());
      throw e;
    }
  }

  /// Update the last active timestamp
  Future<void> _updateLastActive(String userId) async {
    try {
      final now = DateTime.now();
      
      // Update in SharedPreferences
      final sessionJson = _sharedPreferences.getString(_sessionPrefKey);
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        sessionData['lastActive'] = now.toIso8601String();
        await _sharedPreferences.setString(_sessionPrefKey, jsonEncode(sessionData));
      }
      
      // Update in Firebase
      await _firebaseDatabase
          .ref()
          .child(_sessionsPath)
          .child(userId)
          .update({
            'lastActive': now.toIso8601String(),
          });
    } catch (e) {
      // Log but don't throw - this is a non-critical operation
      LoggingService.logError('SessionManager: Error updating last active time', e.toString());
    }
  }

  /// Get basic device information
  Map<String, dynamic> _getDeviceInfo() {
    // In a real app, you would use a device info plugin to get more details
    return {
      'appVersion': AppConstants.appVersion,
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}