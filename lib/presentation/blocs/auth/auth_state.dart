import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  otpSent,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? phoneNumber;
  final String? requestId;
  final String? userId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.requestId,
    this.userId,
    this.errorMessage,
  });

  // Initial state
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  // Loading state
  AuthState copyWithLoading() {
    return AuthState(
      status: AuthStatus.loading,
      phoneNumber: phoneNumber,
      requestId: requestId,
      userId: userId,
    );
  }

  // OTP sent state
  AuthState copyWithOtpSent(String requestId, String phoneNumber) {
    return AuthState(
      status: AuthStatus.otpSent,
      requestId: requestId,
      phoneNumber: phoneNumber,
      userId: userId,
    );
  }

  // Authenticated state
  AuthState copyWithAuthenticated(String userId) {
    return AuthState(
      status: AuthStatus.authenticated,
      phoneNumber: phoneNumber,
      userId: userId,
    );
  }

  // Unauthenticated state
  AuthState copyWithUnauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  // Error state
  AuthState copyWithError(String message) {
    return AuthState(
      status: AuthStatus.error,
      phoneNumber: phoneNumber,
      requestId: requestId,
      userId: userId,
      errorMessage: message,
    );
  }

  // General copy with method
  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? requestId,
    String? userId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, phoneNumber, requestId, userId, errorMessage];
}