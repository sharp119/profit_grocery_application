import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  /// Create a new user
  Future<Either<Failure, User>> createUser({
    required String phoneNumber,
    String? name,
    String? email,
    required bool isOptedInForMarketing,
  });
  
  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String id);
  
  /// Get user by phone number
  Future<Either<Failure, User>> getUserByPhone(String phoneNumber);
  
  /// Update user information
  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? name,
    String? email,
    bool? isOptedInForMarketing,
  });
  
  /// Add an address to the user
  Future<Either<Failure, User>> addAddress({
    required String userId,
    required Address address,
  });
  
  /// Update an address
  Future<Either<Failure, User>> updateAddress({
    required String userId,
    required Address address,
  });
  
  /// Remove an address
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