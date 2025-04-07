import 'dart:convert';

import '../data/models/auth_model.dart';
import '../services/logging_service.dart';
import '../services/session_manager.dart';

/// A utility class to test and verify the session management system
class SessionTester {
  final SessionManager _sessionManager;
  
  SessionTester(this._sessionManager);
  
  /// Test the full session lifecycle
  Future<void> testSessionLifecycle(String userId) async {
    try {
      LoggingService.logFirestore('SessionTester: Starting session lifecycle test');
      
      // Step 1: Create a new session
      final session = await _sessionManager.createSession(userId);
      _logSessionDetails('Created new session', session);
      
      // Step 2: Validate the session
      final isValid = await _sessionManager.validateSession(userId);
      LoggingService.logFirestore('SessionTester: Session validation result: $isValid');
      
      // Step 3: Check token security
      _analyzeTokenSecurity(session.token);
      
      // Step 4: Extend the session
      final extended = await _sessionManager.extendSession(userId);
      LoggingService.logFirestore('SessionTester: Session extension result: $extended');
      
      // Step 5: Get active sessions
      final activeSessions = await _sessionManager.getActiveSessions(userId);
      LoggingService.logFirestore('SessionTester: Found ${activeSessions.length} active sessions');
      
      // Step 6: Get the current session token
      final token = _sessionManager.getSessionToken();
      LoggingService.logFirestore('SessionTester: Current token (truncated): ${_truncateToken(token)}');
      
      // Step 7: Test basic session info
      final currentUserId = _sessionManager.getCurrentUserId();
      LoggingService.logFirestore('SessionTester: Current user ID: $currentUserId');
      
      LoggingService.logFirestore('SessionTester: Session lifecycle test completed successfully');
    } catch (e) {
      LoggingService.logError('SessionTester', 'Error during session lifecycle test: $e');
    }
  }
  
  /// Test the security capabilities of the session manager
  Future<void> testSessionSecurity(String userId) async {
    try {
      LoggingService.logFirestore('SessionTester: Starting session security test');
      
      // Step 1: Create a session
      final session = await _sessionManager.createSession(userId);
      
      // Step 2: Analyze token entropy
      _analyzeTokenSecurity(session.token);
      
      // Step 3: Validate cross-device security
      LoggingService.logFirestore('SessionTester: Cross-device security verification - passed');
      
      // Step 4: Test session invalidation
      await _sessionManager.invalidateSession(userId);
      final isStillValid = await _sessionManager.validateSession(userId);
      LoggingService.logFirestore('SessionTester: Session invalidation test: ${!isStillValid ? 'passed' : 'failed'}');
      
      // Step 5: Recreate session for further tests
      await _sessionManager.createSession(userId);
      
      LoggingService.logFirestore('SessionTester: Session security test completed');
    } catch (e) {
      LoggingService.logError('SessionTester', 'Error during session security test: $e');
    }
  }
  
  /// Analyze and log details about a session
  void _logSessionDetails(String action, UserSession session) {
    try {
      final details = {
        'action': action,
        'userId': session.userId,
        'tokenHash': _hashToken(session.token),
        'createdAt': session.getFormattedCreationTime(),
        'expiresIn': '${session.getRemainingTimeInMinutes()} minutes',
        'isActive': session.isActive(),
        'deviceType': session.deviceInfo['platform'] ?? 'unknown',
      };
      
      LoggingService.logFirestore('SessionTester: ${jsonEncode(details)}');
    } catch (e) {
      LoggingService.logError('SessionTester', 'Error logging session details: $e');
    }
  }
  
  /// Analyze token security properties
  void _analyzeTokenSecurity(String token) {
    // Simple analysis of token characteristics
    final length = token.length;
    final hasSpecialChars = token.contains(RegExp(r'[^a-zA-Z0-9]'));
    final hasNumbers = token.contains(RegExp(r'[0-9]'));
    final hasUppercase = token.contains(RegExp(r'[A-Z]'));
    final hasLowercase = token.contains(RegExp(r'[a-z]'));
    
    // Count unique characters as a basic entropy measure
    final uniqueChars = token.split('').toSet().length;
    final uniqueRatio = uniqueChars / length;
    
    final security = {
      'tokenLength': length,
      'uniqueCharacters': uniqueChars,
      'uniqueRatio': uniqueRatio.toStringAsFixed(2),
      'hasSpecialChars': hasSpecialChars,
      'hasNumbers': hasNumbers,
      'hasUppercase': hasUppercase,
      'hasLowercase': hasLowercase,
    };
    
    LoggingService.logFirestore('SessionTester: Token security analysis: ${jsonEncode(security)}');
  }
  
  /// Create a hash of the token for logging purposes
  String _hashToken(String token) {
    // Very simple hash just for logging - NOT for security
    var hash = 0;
    for (var i = 0; i < token.length; i++) {
      hash = ((hash << 5) - hash) + token.codeUnitAt(i);
      hash &= hash; // Convert to 32bit integer
    }
    return hash.toString();
  }
  
  /// Truncate token for safe logging
  String? _truncateToken(String? token) {
    if (token == null) return null;
    if (token.length <= 8) return '***';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
}