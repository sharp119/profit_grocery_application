import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String requestId;
  final String otp;
  final String phoneNumber;

  const VerifyOtpEvent({
    required this.requestId,
    required this.otp,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [requestId, otp, phoneNumber];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}