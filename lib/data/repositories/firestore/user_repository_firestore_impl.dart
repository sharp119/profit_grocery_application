import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../services/logging_service.dart';
import '../../../services/session_manager_interface.dart';
import '../../models/firestore/user_firestore_model.dart';

class UserRepositoryFirestoreImpl implements UserRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _sharedPreferences;
  final ISessionManager _sessionManager;

  // Collection references
  late final CollectionReference<Map<String, dynamic>> _usersCollection;

  UserRepositoryFirestoreImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences sharedPreferences,
    required ISessionManager sessionManager,
  })  : _firestore = firestore,
        _sharedPreferences = sharedPreferences,
        _sessionManager = sessionManager {
    _usersCollection = _firestore.collection(AppConstants.usersCollection);
  }

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
      final userModel = UserFirestoreModel(
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
        // Save to Firestore with custom document ID
        await _usersCollection.doc(userId).set(userModel.toFirestore());
        
        // Also store basic info in SharedPreferences for quick access
        await _storeUserBasicInfo(userModel);
        
        LoggingService.logFirestore('UserRepository: User created with ID: $userId');
        
        return Right(userModel);
      } catch (e) {
        LoggingService.logError('UserRepository: Firestore error saving user', e.toString());
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
      if (user is UserFirestoreModel) {
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
      // Get user from Firestore
      final docSnapshot = await _usersCollection.doc(id).get();
      
      if (!docSnapshot.exists) {
        // Instead of returning an error, we'll create a basic user object
        // This makes the app more resilient by allowing auto-creation of users
        LoggingService.logFirestore('UserRepository: Creating new user profile for ID: $id');
        
        // Get phone number from SharedPreferences if available
        final phoneNumber = _sharedPreferences.getString(AppConstants.userPhoneKey);
        
        if (phoneNumber == null) {
          // If we don't have a phone number, we can't proceed
          return Left(NotFoundFailure(message: 'User not found and phone number not available'));
        }
        
        // Create a new user with basic info
        final now = DateTime.now();
        final userModel = UserFirestoreModel(
          id: id,
          phoneNumber: phoneNumber,
          name: null,
          email: null,
          addresses: const [],
          createdAt: now,
          lastLogin: now,
          isOptedInForMarketing: false,
        );
        
        // Save the basic user profile to Firestore
        try {
          await _usersCollection.doc(id).set(userModel.toFirestore());
          
          // Also store basic info in SharedPreferences
          await _storeUserBasicInfo(userModel);
          
          LoggingService.logFirestore('UserRepository: Auto-created user profile for ID: $id');
          
          return Right(userModel);
        } catch (e) {
          LoggingService.logError('UserRepository', 'Failed to auto-create user: $e');
          return Left(NotFoundFailure(message: 'User not found'));
        }
      }
      
      // Convert to UserFirestoreModel
      final userModel = UserFirestoreModel.fromFirestore(
        docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        null,
      );
      
      return Right(userModel);
    } catch (e) {
      LoggingService.logError('UserRepository: Failed to get user by ID', e.toString());
      return Left(ServerFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> getUserByPhone(String phoneNumber) async {
    try {
      // Query users collection by phone number
      final querySnapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return Left(NotFoundFailure(message: 'User not found'));
      }
      
      // Get the first user with the matching phone number
      final docSnapshot = querySnapshot.docs.first;
      final userModel = UserFirestoreModel.fromFirestore(
        docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        null,
      );
      
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
      // Query users collection by phone number
      final querySnapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      return Right(querySnapshot.docs.isNotEmpty);
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
          // Update fields in a Map
          final Map<String, dynamic> updates = {};
          
          if (name != null) updates['name'] = name;
          if (email != null) updates['email'] = email;
          if (isOptedInForMarketing != null) {
            updates['isOptedInForMarketing'] = isOptedInForMarketing;
          }
          updates['lastLogin'] = Timestamp.fromDate(DateTime.now());
          
          // Update in Firestore
          await _usersCollection.doc(userId).update(updates);
          
          // Create updated user model
          final updatedUser = UserFirestoreModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: name ?? user.name,
            email: email ?? user.email,
            addresses: user.addresses,
            createdAt: user.createdAt,
            lastLogin: DateTime.now(),
            isOptedInForMarketing: isOptedInForMarketing ?? 
              (user is UserFirestoreModel ? user.isOptedInForMarketing : true),
          );
          
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
          
          // Update in Firestore
          await _usersCollection.doc(userId).update({
            'lastLogin': Timestamp.fromDate(now),
          });
          
          // Create updated user model
          final updatedUser = user is UserFirestoreModel
              ? (user as UserFirestoreModel).copyWith(lastLogin: now)
              : UserFirestoreModel(
                  id: user.id,
                  phoneNumber: user.phoneNumber,
                  name: user.name,
                  email: user.email,
                  addresses: user.addresses,
                  createdAt: user.createdAt,
                  lastLogin: now,
                  isOptedInForMarketing: user is UserFirestoreModel ? (user as UserFirestoreModel).isOptedInForMarketing : true,
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
                  phone: address.phone,
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
                  phone: addresses[i].phone,
                );
              }
            }
          }
          
          addresses.add(newAddress);
          
          // Create updated user model
          final updatedUser = UserFirestoreModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserFirestoreModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firestore
          await _usersCollection.doc(userId).update({
            'addresses': addresses.map((addr) => {
              'id': addr.id,
              'name': addr.name,
              'addressLine': addr.addressLine,
              'city': addr.city,
              'state': addr.state,
              'pincode': addr.pincode,
              'landmark': addr.landmark,
              'isDefault': addr.isDefault,
              'addressType': addr.addressType,
              'phone': addr.phone,
            }).toList(),
          });
          
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
                  phone: addresses[i].phone,
                );
              }
            }
          }
          
          addresses[addressIndex] = address;
          
          // Create updated user model
          final updatedUser = UserFirestoreModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserFirestoreModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firestore
          await _usersCollection.doc(userId).update({
            'addresses': addresses.map((addr) => {
              'id': addr.id,
              'name': addr.name,
              'addressLine': addr.addressLine,
              'city': addr.city,
              'state': addr.state,
              'pincode': addr.pincode,
              'landmark': addr.landmark,
              'isDefault': addr.isDefault,
              'addressType': addr.addressType,
              'phone': addr.phone,
            }).toList(),
          });
          
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
              phone: addresses[0].phone,
            );
          }
          
          // Create updated user model
          final updatedUser = UserFirestoreModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserFirestoreModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firestore
          await _usersCollection.doc(userId).update({
            'addresses': addresses.map((addr) => {
              'id': addr.id,
              'name': addr.name,
              'addressLine': addr.addressLine,
              'city': addr.city,
              'state': addr.state,
              'pincode': addr.pincode,
              'landmark': addr.landmark,
              'isDefault': addr.isDefault,
              'addressType': addr.addressType,
              'phone': addr.phone,
            }).toList(),
          });
          
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
                phone: addresses[i].phone,
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
            phone: addresses[targetAddressIndex].phone,
          );
          
          // Create updated user model
          final updatedUser = UserFirestoreModel(
            id: user.id,
            phoneNumber: user.phoneNumber,
            name: user.name,
            email: user.email,
            addresses: addresses,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isOptedInForMarketing: user is UserFirestoreModel ? user.isOptedInForMarketing : true,
          );
          
          // Update in Firestore
          await _usersCollection.doc(userId).update({
            'addresses': addresses.map((addr) => {
              'id': addr.id,
              'name': addr.name,
              'addressLine': addr.addressLine,
              'city': addr.city,
              'state': addr.state,
              'pincode': addr.pincode,
              'landmark': addr.landmark,
              'isDefault': addr.isDefault,
              'addressType': addr.addressType,
              'phone': addr.phone,
            }).toList(),
          });
          
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
