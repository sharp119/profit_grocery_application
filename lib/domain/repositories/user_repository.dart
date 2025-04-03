import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../../core/errors/failures.dart';

abstract class UserRepository {
  /// Get current user details
  Future<Either<Failure, User>> getCurrentUser();
  
  /// Get user profile by ID
  Future<Either<Failure, User>> getUserById(String userId);
  
  /// Update user profile
  Future<Either<Failure, User>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
  });
  
  /// Add a new address to user profile
  Future<Either<Failure, User>> addAddress({
    required String userId,
    required Address address,
  });
  
  /// Update an existing address
  Future<Either<Failure, User>> updateAddress({
    required String userId,
    required Address address,
  });
  
  /// Remove an address from user profile
  Future<Either<Failure, User>> removeAddress({
    required String userId,
    required String addressId,
  });
  
  /// Set an address as default
  Future<Either<Failure, User>> setDefaultAddress({
    required String userId,
    required String addressId,
  });
}