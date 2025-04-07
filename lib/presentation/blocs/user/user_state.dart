import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

enum UserStatus {
  initial,
  loading,
  loaded,
  created,
  updated,
  error,
}

class UserState extends Equatable {
  final UserStatus status;
  final User? user;
  final String? errorMessage;

  const UserState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory UserState.initial() {
    return const UserState(status: UserStatus.initial);
  }

  UserState copyWith({
    UserStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  UserState copyWithLoading() {
    return copyWith(status: UserStatus.loading);
  }

  UserState copyWithLoaded(User user) {
    return copyWith(
      status: UserStatus.loaded,
      user: user,
      errorMessage: null,
    );
  }

  UserState copyWithCreated(User user) {
    return copyWith(
      status: UserStatus.created,
      user: user,
      errorMessage: null,
    );
  }

  UserState copyWithUpdated(User user) {
    return copyWith(
      status: UserStatus.updated,
      user: user,
      errorMessage: null,
    );
  }

  UserState copyWithError(String message) {
    return copyWith(
      status: UserStatus.error,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
