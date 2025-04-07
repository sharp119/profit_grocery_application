import '../../domain/entities/user.dart';

class UserModel extends User {
  final bool isOptedInForMarketing;

  const UserModel({
    required super.id,
    required super.phoneNumber,
    super.name,
    super.email,
    super.addresses = const [],
    required super.createdAt,
    required super.lastLogin,
    required this.isOptedInForMarketing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse addresses if present
    List<Address> addresses = [];
    if (json['addresses'] != null) {
      addresses = List<Address>.from(
        (json['addresses'] as List).map(
          (addr) => AddressModel.fromJson(Map<String, dynamic>.from(addr)),
        ),
      );
    }

    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      email: json['email'],
      addresses: addresses,
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      isOptedInForMarketing: json['isOptedInForMarketing'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'addresses': addresses
          .map((addr) => (addr as AddressModel).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isOptedInForMarketing': isOptedInForMarketing,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    List<Address>? addresses,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isOptedInForMarketing,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isOptedInForMarketing: isOptedInForMarketing ?? this.isOptedInForMarketing,
    );
  }
}

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.name,
    required super.addressLine,
    required super.city,
    required super.state,
    required super.pincode,
    super.landmark,
    super.isDefault = false,
    super.addressType = 'home',
  });

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
}