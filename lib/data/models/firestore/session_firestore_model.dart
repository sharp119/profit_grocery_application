import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/auth_model.dart';

class SessionFirestoreModel {
  final String userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActive;
  final Map<String, dynamic> deviceInfo;

  const SessionFirestoreModel({
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActive,
    required this.deviceInfo,
  });

  /// Create a SessionFirestoreModel from a UserSession
  factory SessionFirestoreModel.fromUserSession(UserSession session) {
    return SessionFirestoreModel(
      userId: session.userId,
      token: session.token,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      lastActive: session.lastActive,
      deviceInfo: session.deviceInfo,
    );
  }

  /// Convert to UserSession model
  UserSession toUserSession() {
    return UserSession(
      userId: userId,
      token: token,
      createdAt: createdAt,
      expiresAt: expiresAt,
      lastActive: lastActive,
      deviceInfo: deviceInfo,
    );
  }

  /// Convert Firestore document to SessionFirestoreModel
  factory SessionFirestoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Document data was null');
    }

    return SessionFirestoreModel(
      userId: data['userId'] ?? '',
      token: data['token'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      deviceInfo: Map<String, dynamic>.from(data['deviceInfo'] ?? {}),
    );
  }

  /// Convert SessionFirestoreModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'token': token,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'deviceInfo': deviceInfo,
    };
  }
}
