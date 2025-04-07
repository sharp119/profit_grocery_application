# SessionManager Service Documentation

The SessionManager is a critical component of the ProfitGrocery authentication system, responsible for secure token generation, session storage, tracking, and validation.

## Core Features

### 1. Secure Token Generation

The SessionManager implements cryptographically secure token generation using:

- SHA-256 hashing algorithm
- Secure random number generation
- Multiple sources of entropy (user ID, timestamp, random salt, nonce)
- Unique token per session

Code excerpt:
```dart
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
```

### 2. Session Storage in SharedPreferences

Sessions are securely stored in SharedPreferences for persistence across app restarts:

- Full session JSON stored for complete data
- Individual components stored for quick access
- Automatic cleanup of expired sessions

### 3. Firebase Realtime Database Session Tracking

Sessions are tracked in Firebase to enable:

- Cross-device awareness
- Admin monitoring capabilities
- Session invalidation from server side
- Last active timestamp tracking

Schema:
```
/sessions/{userId}
  - token: string
  - createdAt: timestamp
  - expiresAt: timestamp
  - lastActive: timestamp
  - deviceInfo: object
  - ipAddress: string (optional)
  - userAgent: string (optional)
  - sessionType: string
```

### 4. Session Validation Logic

Comprehensive validation logic ensures:

- Temporal validity (not expired)
- Token integrity
- Cross-reference validation between local and server data
- Automatic extension capability

## Security Considerations

1. **Token Security**: Uses cryptographic hashing and multiple entropy sources
2. **Expiration**: Sessions automatically expire after configurable timeout
3. **Invalidation**: Sessions can be forcibly invalidated during logout
4. **Device Tracking**: Sessions record device information for security monitoring
5. **Cross-device Awareness**: Login on a new device can optionally invalidate existing sessions

## Usage

### Initialization

```dart
final sessionManager = SessionManager();
await sessionManager.init(
  sharedPreferences: sharedPreferences,
  firebaseDatabase: firebaseDatabase,
);
```

### Creating a Session

```dart
final session = await sessionManager.createSession(userId);
```

### Validating a Session

```dart
final isValid = await sessionManager.validateSession(userId);
```

### Extending a Session

```dart
final extended = await sessionManager.extendSession(userId);
```

### Invalidating a Session (Logout)

```dart
await sessionManager.invalidateSession(userId);
```

## Testing

The SessionTester utility provides comprehensive testing capabilities:

- Session lifecycle testing
- Security analysis
- Cross-device validation

## Future Enhancements

1. **Multiple Device Support**: Allow users to view and manage sessions from multiple devices
2. **Anomaly Detection**: Flag suspicious login patterns
3. **Rate Limiting**: Prevent brute force attacks
4. **Geo-fencing**: Add location-based security
5. **Two-Factor Authentication**: Add additional security layer