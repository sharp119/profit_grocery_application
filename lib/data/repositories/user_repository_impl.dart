import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/logging_service.dart';
import '../../services/session_manager.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseDatabase _firebaseDatabase;
  final SharedPreferences _sharedPreferences;
  final SessionManager _sessionManager;

  UserRepositoryImpl({
    required FirebaseDatabase firebaseDatabase,
    required SharedPreferences sharedPreferences,
    SessionManager? sessionManager,
  })  : _firebaseDatabase = firebaseDatabase,
        _sharedPreferences = sharedPreferences,
        _sessionManager = sessionManager ?? SessionManager();

  @override
  Future<Either<Failure, User>> createUser({
    required String phoneNumber,
    String? name,
    String? email,
    required bool isOptedInForMarketing,
  }) async {
    try {
      // Check if user already exists first
      final userExistsResult = await checkUserExists(phoneNumber);
      
      // If there was an error checking user existence, continue anyway
      // But if user exists, return an error
      final bool userExists = userExistsResult.fold(
        (failure) => false, // Assume user doesn't exist if we couldn't check
        (exists) => exists,
      );
      
      if (userExists) {
        LoggingService.logFirestore('UserRepository: User with phone $phoneNumber already exists');
        return Left(ValidationFailure(message: 'User with this phone number already exists'));
      }

      // Get current user ID from SharedPreferences
      final userId = _sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (userId == null) {
        // Try to get from the old key for compatibility
        final alternativeUserId = _sharedPreferences.getString('user_id');
        
        if (alternativeUserId == null) {
          // Generate a new ID as fallback
          final newUserId = DateTime.now().millisecondsSinceEpoch.toString();
          await _sharedPreferences.setString(AppConstants.userTokenKey, newUserId);
          LoggingService.logFirestore('UserRepository: Generated new user ID: $newUserId');
          
          // Create user with this ID
          return await _createUserWithId(
            userId: newUserId,
            phoneNumber: phoneNumber,
            name: name,
            email: email,
            isOptedInForMarketing: isOptedInForMarketing
          );
        } else {
          // Use alternative ID
          await _sharedPreferences.setString(AppConstants.userTokenKey, alternativeUserId);
          LoggingService.logFirestore('UserRepository: Using alternative user ID: $alternativeUserId');
          
          return await _createUserWithId(
            userId: alternativeUserId,
            phoneNumber: phoneNumber,
            name: name,
            email: email,
            isOptedInForMarketing: isOptedInForMarketing
          );
        }
      }
      
      LoggingService.logFirestore('UserRepository: Using existing user ID: $userId');
      return await _createUserWithId(
        userId: userId,
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        isOptedInForMarketing: isOptedInForMarketing
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to create user', e.toString());
      return Left(ServerFailure(message: 'Failed to create user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Tuple2<User, String>>> createUserAndLogin({
    required String phoneNumber,
    String? name,
    String? email,
    required bool isOptedInForMarketing,
  }) async {
    try {
      // First create the user
      final userResult = await createUser(
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        isOptedInForMarketing: isOptedInForMarketing,
      );
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          try {
            // Create a session for the user (auto-login)
            final session = await _sessionManager.createSession(user.id);
            final authToken = session.token;
            
            // Store the token in SharedPreferences with consistent keys
            await _sharedPreferences.setString('auth_token', authToken);
            
            // Update user's last login time
            await updateLastLogin(user.id);
            
            LoggingService.logFirestore('UserRepository: User created and auto-logged in: ${user.id}');
            
            return Right(Tuple2(user, authToken));
          } catch (e) {
            LoggingService.logError('UserRepository: Failed to auto-login after registration', e.toString());
            // Still return the user but with an empty token
            return Right(Tuple2(user, ''));
          }
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to create user and auto-login', e.toString());
      return Left(ServerFailure(message: 'Failed to create user and auto-login: ${e.toString()}'));
    }
  }
  
  // Helper method to create user with a specific ID
  Future<Either<Failure, User>> _createUserWithId({
    required String userId,
    required String phoneNumber,
    String? name,
    String? email,
    required bool isOptedInForMarketing,
  }) async {
    try {
      
      // Create user model
      final now = DateTime.now();
      final userModel = UserModel(
        id: userId,
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        addresses: const [],
        createdAt: now,
        lastLogin: now,
        isOptedInForMarketing: isOptedInForMarketing,
      );
      
      try {
        // Prepare the data for Firebase
        final userData = userModel.toJson();
        LoggingService.logFirestore('UserRepository: About to save user data to Firebase: $userId');
        
        // Save to Firebase Realtime Database with error handling
        final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
        await usersRef.child(userId).set(userData);
        
        // Also store basic info in SharedPreferences for quick access
        await _storeUserBasicInfo(userModel);
        
        LoggingService.logFirestore('UserRepository: User created with ID: $userId');
        
        return Right(userModel);
      } catch (e) {
        LoggingService.logError('UserRepository: Firebase error saving user', e.toString());
        return Left(ServerFailure(message: 'Failed to save user to database: ${e.toString()}'));
      }
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to create user with ID', e.toString());
      return Left(ServerFailure(message: 'Failed to create user: ${e.toString()}'));
    }
  }
  
  /// Store basic user info in SharedPreferences for quick access
  Future<void> _storeUserBasicInfo(User user) async {
    try {
      // Store the bare minimum needed for quick access
      await _sharedPreferences.setString(AppConstants.userTokenKey, user.id);
      await _sharedPreferences.setString(AppConstants.userPhoneKey, user.phoneNumber);
      
      // Store optional data if available
      if (user.name != null) {
        await _sharedPreferences.setString('user_name', user.name!);
      }
      
      if (user.email != null) {
        await _sharedPreferences.setString('user_email', user.email!);
      }
      
      // Store basic user preferences
      if (user is UserModel) {
        await _sharedPreferences.setBool('user_marketing_opt_in', user.isOptedInForMarketing);
      }
      
      // Store login time for auto-login expiry
      await _sharedPreferences.setString('user_last_login', DateTime.now().toIso8601String());
      
      // Mark that user is complete and registered
      await _sharedPreferences.setBool('user_registration_complete', true);
      
      LoggingService.logFirestore('UserRepository: Stored basic user info in SharedPreferences');
    } catch (e) {
      // Just log the error but don't throw - this is a non-critical operation
      LoggingService.logError('UserRepository: Failed to store user info in SharedPreferences', e.toString());
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String id) async {
    try {
      // Get user from Firebase Realtime Database
      final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
      final snapshot = await usersRef.child(id).get();
      
      if (!snapshot.exists) {
        return Left(NotFoundFailure(message: 'User not found'));
      }
      
      // Convert snapshot to UserModel
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final userModel = UserModel.fromJson(userData);
      
      return Right(userModel);
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to get user by ID', e.toString());
      return Left(ServerFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> getUserByPhone(String phoneNumber) async {
    try {
      // Get user from Firebase Realtime Database
      final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
      final query = usersRef.orderByChild('phoneNumber').equalTo(phoneNumber);
      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return Left(NotFoundFailure(message: 'User not found'));
      }
      
      // Get the first user with the matching phone number
      final userData = (snapshot.value as Map).values.first as Map<dynamic, dynamic>;
      final userModel = UserModel.fromJson(Map<String, dynamic>.from(userData));
      
      // Store some basic user info in SharedPreferences for quick access
      await _storeUserBasicInfo(userModel);
      
      return Right(userModel);
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to get user by phone', e.toString());
      return Left(ServerFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> checkUserExists(String phoneNumber) async {
    try {
      // Check if user exists in Firebase by phone number
      final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
      final query = usersRef.orderByChild('phoneNumber').equalTo(phoneNumber);
      final snapshot = await query.get();
      
      return Right(snapshot.exists);
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to check if user exists', e.toString());
      return Left(ServerFailure(message: 'Failed to check if user exists: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? name,
    String? email,
    bool? isOptedInForMarketing,
  }) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Create updated user model
          final updatedUser = UserModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: name ?? user.name,
            email: email ?? user.email,
            addresses: user.addresses,
            createdAt: user.createdAt,
            lastLogin: DateTime.now(),
            isOptedInForMarketing: isOptedInForMarketing ?? 
              (user is UserModel ? user.isOptedInForMarketing : true),
          );
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          final updates = <String, dynamic>{};
          
          if (name != null) updates['name'] = name;
          if (email != null) updates['email'] = email;
          if (isOptedInForMarketing != null) {
            updates['isOptedInForMarketing'] = isOptedInForMarketing;
          }
          updates['lastLogin'] = updatedUser.lastLogin.toIso8601String();
          
          await usersRef.child(userId).update(updates);
          
          // Also update in SharedPreferences for quick access
          await _storeUserBasicInfo(updatedUser);
          
          LoggingService.logFirestore('UserRepository: User updated with ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to update user', e.toString());
      return Left(ServerFailure(message: 'Failed to update user: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, User>> updateLastLogin(String userId) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Update last login time
          final now = DateTime.now();
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          await usersRef.child(userId).update({
            'lastLogin': now.toIso8601String(),
          });
          
          // Create updated user model
          final updatedUser = user is UserModel
              ? (user as UserModel).copyWith(lastLogin: now)
              : UserModel(
                  id: user.id,
                  phoneNumber: user.phoneNumber,
                  name: user.name,
                  email: user.email,
                  addresses: user.addresses,
                  createdAt: user.createdAt,
                  lastLogin: now,
                  isOptedInForMarketing: user is UserModel ? (user as UserModel).isOptedInForMarketing : true,
                );
          
          LoggingService.logFirestore('UserRepository: Updated last login for user ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to update last login', e.toString());
      return Left(ServerFailure(message: 'Failed to update last login: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> addAddress({
    required String userId,
    required Address address,
  }) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Add the new address
          final addresses = List<Address>.from(user.addresses);
          
          // If this is the first address, make it the default
          final newAddress = address.isDefault || addresses.isEmpty
              ? address
              : Address(
                  id: address.id,
                  name: address.name,
                  addressLine: address.addressLine,
                  city: address.city,
                  state: address.state,
                  pincode: address.pincode,
                  landmark: address.landmark,
                  isDefault: true,
                  addressType: address.addressType,
                );
          
          // If the new address is default, unset default flag on existing addresses
          if (newAddress.isDefault) {
            for (var i = 0; i < addresses.length; i++) {
              if (addresses[i].isDefault) {
                addresses[i] = Address(
                  id: addresses[i].id,
                  name: addresses[i].name,
                  addressLine: addresses[i].addressLine,
                  city: addresses[i].city,
                  state: addresses[i].state,
                  pincode: addresses[i].pincode,
                  landmark: addresses[i].landmark,
                  isDefault: false,
                  addressType: addresses[i].addressType,
                );
              }
            }
          }
          
          addresses.add(newAddress);
          
          // Create updated user model
          final updatedUser = UserModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          await usersRef.child(userId).child('addresses').set(
                addresses
                    .map((addr) => {
                          'id': addr.id,
                          'name': addr.name,
                          'addressLine': addr.addressLine,
                          'city': addr.city,
                          'state': addr.state,
                          'pincode': addr.pincode,
                          'landmark': addr.landmark,
                          'isDefault': addr.isDefault,
                          'addressType': addr.addressType,
                        })
                    .toList(),
              );
          
          LoggingService.logFirestore('UserRepository: Address added for user ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to add address', e.toString());
      return Left(ServerFailure(message: 'Failed to add address: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateAddress({
    required String userId,
    required Address address,
  }) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Find and update the address
          final addresses = List<Address>.from(user.addresses);
          var addressIndex = -1;
          
          for (var i = 0; i < addresses.length; i++) {
            if (addresses[i].id == address.id) {
              addressIndex = i;
              break;
            }
          }
          
          if (addressIndex == -1) {
            return Left(NotFoundFailure(message: 'Address not found'));
          }
          
          // If the updated address is default, unset default flag on existing addresses
          if (address.isDefault) {
            for (var i = 0; i < addresses.length; i++) {
              if (i != addressIndex && addresses[i].isDefault) {
                addresses[i] = Address(
                  id: addresses[i].id,
                  name: addresses[i].name,
                  addressLine: addresses[i].addressLine,
                  city: addresses[i].city,
                  state: addresses[i].state,
                  pincode: addresses[i].pincode,
                  landmark: addresses[i].landmark,
                  isDefault: false,
                  addressType: addresses[i].addressType,
                );
              }
            }
          }
          
          addresses[addressIndex] = address;
          
          // Create updated user model
          final updatedUser = UserModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          await usersRef.child(userId).child('addresses').set(
                addresses
                    .map((addr) => {
                          'id': addr.id,
                          'name': addr.name,
                          'addressLine': addr.addressLine,
                          'city': addr.city,
                          'state': addr.state,
                          'pincode': addr.pincode,
                          'landmark': addr.landmark,
                          'isDefault': addr.isDefault,
                          'addressType': addr.addressType,
                        })
                    .toList(),
              );
          
          LoggingService.logFirestore('UserRepository: Address updated for user ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to update address', e.toString());
      return Left(ServerFailure(message: 'Failed to update address: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> removeAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Find and remove the address
          final addresses = List<Address>.from(user.addresses);
          var removedAddress = addresses.firstWhere(
            (addr) => addr.id == addressId,
            orElse: () => const Address(
              id: '',
              name: '',
              addressLine: '',
              city: '',
              state: '',
              pincode: '',
            ),
          );
          
          if (removedAddress.id.isEmpty) {
            return Left(NotFoundFailure(message: 'Address not found'));
          }
          
          addresses.removeWhere((addr) => addr.id == addressId);
          
          // If the removed address was default, set a new default if there are other addresses
          if (removedAddress.isDefault && addresses.isNotEmpty) {
            addresses[0] = Address(
              id: addresses[0].id,
              name: addresses[0].name,
              addressLine: addresses[0].addressLine,
              city: addresses[0].city,
              state: addresses[0].state,
              pincode: addresses[0].pincode,
              landmark: addresses[0].landmark,
              isDefault: true,
              addressType: addresses[0].addressType,
            );
          }
          
          // Create updated user model
          final updatedUser = UserModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          await usersRef.child(userId).child('addresses').set(
                addresses
                    .map((addr) => {
                          'id': addr.id,
                          'name': addr.name,
                          'addressLine': addr.addressLine,
                          'city': addr.city,
                          'state': addr.state,
                          'pincode': addr.pincode,
                          'landmark': addr.landmark,
                          'isDefault': addr.isDefault,
                          'addressType': addr.addressType,
                        })
                    .toList(),
              );
          
          LoggingService.logFirestore('UserRepository: Address removed for user ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to remove address', e.toString());
      return Left(ServerFailure(message: 'Failed to remove address: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      // Get the current user data
      final userResult = await getUserById(userId);
      
      return await userResult.fold(
        (failure) async => Left(failure),
        (user) async {
          // Find the address and set it as default
          final addresses = List<Address>.from(user.addresses);
          var targetAddressIndex = -1;
          
          for (var i = 0; i < addresses.length; i++) {
            if (addresses[i].id == addressId) {
              targetAddressIndex = i;
              continue;
            }
            
            // Unset default for all other addresses
            if (addresses[i].isDefault) {
              addresses[i] = Address(
                id: addresses[i].id,
                name: addresses[i].name,
                addressLine: addresses[i].addressLine,
                city: addresses[i].city,
                state: addresses[i].state,
                pincode: addresses[i].pincode,
                landmark: addresses[i].landmark,
                isDefault: false,
                addressType: addresses[i].addressType,
              );
            }
          }
          
          if (targetAddressIndex == -1) {
            return Left(NotFoundFailure(message: 'Address not found'));
          }
          
          // Set the target address as default
          addresses[targetAddressIndex] = Address(
            id: addresses[targetAddressIndex].id,
            name: addresses[targetAddressIndex].name,
            addressLine: addresses[targetAddressIndex].addressLine,
            city: addresses[targetAddressIndex].city,
            state: addresses[targetAddressIndex].state,
            pincode: addresses[targetAddressIndex].pincode,
            landmark: addresses[targetAddressIndex].landmark,
            isDefault: true,
            addressType: addresses[targetAddressIndex].addressType,
          );
          
          // Create updated user model
          final updatedUser = UserModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firebase Realtime Database
          final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
          await usersRef.child(userId).child('addresses').set(
                addresses
                    .map((addr) => {
                          'id': addr.id,
                          'name': addr.name,
                          'addressLine': addr.addressLine,
                          'city': addr.city,
                          'state': addr.state,
                          'pincode': addr.pincode,
                          'landmark': addr.landmark,
                          'isDefault': addr.isDefault,
                          'addressType': addr.addressType,
                        })
                    .toList(),
              );
          
          LoggingService.logFirestore('UserRepository: Default address set for user ID: $userId');
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to set default address', e.toString());
      return Left(ServerFailure(message: 'Failed to set default address: ${e.toString()}'));
    }
  }
}