/// Represents the result of a phone number check
class PhoneCheckResult {
  final bool exists;
  final String? userId;
  final String phoneNumber;

  PhoneCheckResult({
    required this.exists,
    this.userId,
    required this.phoneNumber,
  });
}

/// Represents an active user session
class UserSession {
  final String userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActive;
  final Map<String, dynamic> deviceInfo;

  UserSession({
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActive,
    required this.deviceInfo,
  });

  /// Check if the session is currently active
  bool isActive() {
    return DateTime.now().isBefore(expiresAt);
  }

  /// Convert to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'deviceInfo': deviceInfo,
    };
  }

  /// Create from a JSON map
  factory UserSession.fromJson(String userId, Map<String, dynamic> json) {
    return UserSession(
      userId: userId,
      token: json['token'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      lastActive: DateTime.parse(json['lastActive']),
      deviceInfo: json['deviceInfo'],
    );
  }

  /// Create a copy with updated fields
  UserSession copyWith({
    String? userId,
    String? token,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActive,
    Map<String, dynamic>? deviceInfo,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActive: lastActive ?? this.lastActive,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

/// Authentication result containing token and user information
class AuthResult {
  final String token;
  final String userId;
  final bool isNewUser;
  final UserSession session;

  AuthResult({
    required this.token,
    required this.userId,
    required this.isNewUser,
    required this.session,
  });
}