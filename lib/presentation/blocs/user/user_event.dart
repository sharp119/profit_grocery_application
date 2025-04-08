import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class CreateUserProfileEvent extends UserEvent {
  final String phoneNumber;
  final String? name;
  final String? email;
  final bool isOptedInForMarketing;

  const CreateUserProfileEvent({
    required this.phoneNumber,
    this.name,
    this.email,
    required this.isOptedInForMarketing,
  });

  @override
  List<Object?> get props => [phoneNumber, name, email, isOptedInForMarketing];
}

class LoadUserProfileEvent extends UserEvent {
  final String userId;

  const LoadUserProfileEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUserProfileEvent extends UserEvent {
  final String? name;
  final String? email;
  final bool? isOptedInForMarketing;

  const UpdateUserProfileEvent({
    this.name,
    this.email,
    this.isOptedInForMarketing,
  });

  @override
  List<Object?> get props => [name, email, isOptedInForMarketing];
}

// Address-related events
class AddAddressEvent extends UserEvent {
  final String userId;
  final Address address;

  const AddAddressEvent({
    required this.userId,
    required this.address,
  });

  @override
  List<Object> get props => [userId, address];
}

class UpdateAddressEvent extends UserEvent {
  final String userId;
  final Address address;

  const UpdateAddressEvent({
    required this.userId,
    required this.address,
  });

  @override
  List<Object> get props => [userId, address];
}

class RemoveAddressEvent extends UserEvent {
  final String userId;
  final String addressId;

  const RemoveAddressEvent({
    required this.userId,
    required this.addressId,
  });

  @override
  List<Object> get props => [userId, addressId];
}

class SetDefaultAddressEvent extends UserEvent {
  final String userId;
  final String addressId;

  const SetDefaultAddressEvent({
    required this.userId,
    required this.addressId,
  });

  @override
  List<Object> get props => [userId, addressId];
}
