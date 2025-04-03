import 'dart:convert';

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String phoneNumber,
    String? name,
    String? email,
    List<AddressModel> addresses = const [],
    required DateTime createdAt,
    required DateTime lastLogin,
  }) : super(
          id: id,
          phoneNumber: phoneNumber,
          name: name,
          email: email,
          addresses: addresses,
          createdAt: createdAt,
          lastLogin: lastLogin,
        );

  // Factory constructor to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      email: json['email'],
      addresses: json['addresses'] != null
          ? List<AddressModel>.from(
              json['addresses'].map((address) => AddressModel.fromJson(address)))
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'addresses': addresses
          .map((address) => (address as AddressModel).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    List<AddressModel>? addresses,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      addresses: addresses ?? List<AddressModel>.from(this.addresses.map((e) => e as AddressModel)),
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Create an empty user model
  static UserModel empty() {
    return UserModel(
      id: '',
      phoneNumber: '',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }
}

class AddressModel extends Address {
  const AddressModel({
    required String id,
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
    String addressType = 'home',
  }) : super(
          id: id,
          name: name,
          addressLine: addressLine,
          city: city,
          state: state,
          pincode: pincode,
          landmark: landmark,
          isDefault: isDefault,
          addressType: addressType,
        );

  // Factory constructor to create an AddressModel from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      name: json['name'],
      addressLine: json['addressLine'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      landmark: json['landmark'],
      isDefault: json['isDefault'] ?? false,
      addressType: json['addressType'] ?? 'home',
    );
  }

  // Convert AddressModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
      'addressType': addressType,
    };
  }

  // Create a copy of the address with updated fields
  AddressModel copyWith({
    String? id,
    String? name,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
    String? addressType,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      addressType: addressType ?? this.addressType,
    );
  }
}