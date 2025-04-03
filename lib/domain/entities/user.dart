import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final List<Address> addresses;
  final DateTime createdAt;
  final DateTime lastLogin;

  const User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.addresses = const [],
    required this.createdAt,
    required this.lastLogin,
  });

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        name,
        email,
        addresses,
        createdAt,
        lastLogin,
      ];
}

class Address extends Equatable {
  final String id;
  final String name;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final String addressType; // 'home', 'work', 'other'

  const Address({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
    this.addressType = 'home',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        addressLine,
        city,
        state,
        pincode,
        landmark,
        isDefault,
        addressType,
      ];
}