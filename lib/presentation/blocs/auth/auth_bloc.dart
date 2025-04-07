import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../services/logging_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthState.initial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final userId = await _authRepository.getCurrentUserId();
        if (userId != null && !emit.isDone) {
          emit(state.copyWithAuthenticated(userId));
        } else if (!emit.isDone) {
          emit(state.copyWithUnauthenticated());
        }
      } else if (!emit.isDone) {
        emit(state.copyWithUnauthenticated());
      }
    } catch (e) {
      LoggingService.logError('AuthBloc: Error checking auth status', e.toString());
      if (!emit.isDone) {
        emit(state.copyWithError('Failed to check auth status: $e'));
      }
    }
  }

  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    LoggingService.logFirestore('AuthBloc: Sending OTP to phone ${event.phoneNumber}');
    emit(state.copyWithLoading());
    
    try {
      final result = await _authRepository.sendOTP(event.phoneNumber);
      
      await result.fold(
        (failure) async {
          LoggingService.logError('AuthBloc: Failed to send OTP', failure.message);
          if (!emit.isDone) emit(state.copyWithError(failure.message));
        },
        (requestId) async {
          LoggingService.logFirestore('AuthBloc: OTP sent successfully, reqId: $requestId');
          print('AuthBloc: About to emit OTP sent state with requestId: $requestId and phone: ${event.phoneNumber}');
          final newState = state.copyWithOtpSent(requestId, event.phoneNumber);
          print('AuthBloc: Created new state: ${newState.status}, phoneNumber: ${newState.phoneNumber}, requestId: ${newState.requestId}');
          if (!emit.isDone) emit(newState);
          print('AuthBloc: Emitted new state');
        },
      );
    } catch (e) {
      LoggingService.logError('AuthBloc: Exception during OTP send', e.toString());
      if (!emit.isDone) emit(state.copyWithError('Failed to send OTP: $e'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    LoggingService.logFirestore('AuthBloc: Verifying OTP for requestId: ${event.requestId}');
    emit(state.copyWithLoading());
    
    try {
      final result = await _authRepository.verifyOTP(
        requestId: event.requestId,
        otp: event.otp,
        phoneNumber: event.phoneNumber,
      );
      
      await result.fold(
        (failure) async {
          LoggingService.logError('AuthBloc: Failed to verify OTP', failure.message);
          if (!emit.isDone) emit(state.copyWithError(failure.message));
        },
        (token) async {
          LoggingService.logFirestore('AuthBloc: OTP verified successfully');
          final userId = await _authRepository.getCurrentUserId();
          if (userId != null && !emit.isDone) {
            LoggingService.logFirestore('AuthBloc: User authenticated with ID: $userId');
            emit(state.copyWithAuthenticated(userId));
          } else if (!emit.isDone) {
            LoggingService.logError('AuthBloc: Failed to get user ID', 'User ID is null');
            emit(state.copyWithError('Failed to get user ID'));
          }
        },
      );
    } catch (e) {
      LoggingService.logError('AuthBloc: Exception during OTP verification', e.toString());
      if (!emit.isDone) emit(state.copyWithError('Failed to verify OTP: $e'));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWithLoading());
    
    await _authRepository.logout();
    
    if (!emit.isDone) emit(state.copyWithUnauthenticated());
  }
}