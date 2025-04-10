class ServerException implements Exception {
  final String message;

  ServerException({this.message = 'Server error occurred'});
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Cache error occurred'});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Network error occurred'});
}

class AuthException implements Exception {
  final String message;

  AuthException({this.message = 'Authentication error occurred'});
}

class ValidationException implements Exception {
  final String message;

  ValidationException({required this.message});
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException({required this.message});
}

class CouponException implements Exception {
  final String message;

  CouponException({required this.message});
}

class OrderException implements Exception {
  final String message;

  OrderException({required this.message});
}
