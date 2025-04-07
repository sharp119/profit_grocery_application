import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
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
    LoggingService.logFirestore('AuthBloc: Checking authentication status');
    try {
      emit(state.copyWithLoading());
      
      // First check if we have the auth_completed flag set
      final sharedPrefs = await SharedPreferences.getInstance();
      final authCompleted = sharedPrefs.getBool(AppConstants.authCompletedKey) ?? false;
      final userId = sharedPrefs.getString(AppConstants.userTokenKey);
      
      LoggingService.logFirestore('AuthBloc: Initial SharedPreferences check - authCompleted: $authCompleted, userId: $userId');
      
      if (!authCompleted || userId == null) {
        LoggingService.logFirestore('AuthBloc: Auth not completed or no userId found in SharedPreferences');
        if (!emit.isDone) {
          emit(state.copyWithUnauthenticated());
        }
        return;
      }
      
      // Check with the repository for full validation
      final isLoggedIn = await _authRepository.isLoggedIn();
      LoggingService.logFirestore('AuthBloc: Repository login check result: $isLoggedIn');
      
      if (isLoggedIn) {
        final confirmedUserId = await _authRepository.getCurrentUserId();
        if (confirmedUserId != null && !emit.isDone) {
          LoggingService.logFirestore('AuthBloc: User is authenticated with ID: $confirmedUserId');
          emit(state.copyWithAuthenticated(confirmedUserId));
        } else if (!emit.isDone) {
          LoggingService.logFirestore('AuthBloc: User ID not found after isLoggedIn check');
          emit(state.copyWithUnauthenticated());
        }
      } else if (!emit.isDone) {
        LoggingService.logFirestore('AuthBloc: User is not logged in according to repository');
        emit(state.copyWithUnauthenticated());
      }
    } catch (e) {
      LoggingService.logError('AuthBloc: Error checking auth status', e.toString());
      // If there's an error during auth check, we'll try to recover
      // by checking basic SharedPreferences data
      try {
        final sharedPrefs = await SharedPreferences.getInstance();
        final userId = sharedPrefs.getString(AppConstants.userTokenKey);
        final authCompleted = sharedPrefs.getBool(AppConstants.authCompletedKey) ?? false;
        
        if (authCompleted && userId != null) {
          LoggingService.logFirestore('AuthBloc: Recovering from auth check error using SharedPreferences data');
          if (!emit.isDone) {
            emit(state.copyWithAuthenticated(userId));
          }
          return;
        }
      } catch (fallbackError) {
        LoggingService.logError('AuthBloc: Error in fallback auth check', fallbackError.toString());
      }
      
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