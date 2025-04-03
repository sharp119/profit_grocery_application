import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure({required this.message});
  
  @override
  List<Object> get props => [message];
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure({required String message}) : super(message: message);
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message: message);
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection issue. Please check your internet connection.'}) 
      : super(message: message);
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({required String message}) : super(message: message);
}

// User not found failures
class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({String message = 'User not found.'}) 
      : super(message: message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message: message);
}

// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({required String message}) : super(message: message);
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({String message = 'Permission denied.'}) 
      : super(message: message);
}

// Coupon failures
class CouponFailure extends Failure {
  const CouponFailure({required String message}) : super(message: message);
}

// Order failures
class OrderFailure extends Failure {
  const OrderFailure({required String message}) : super(message: message);
}

// Payment failures
class PaymentFailure extends Failure {
  const PaymentFailure({required String message}) : super(message: message);
}