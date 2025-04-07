import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../services/logging_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UserState.initial()) {
    on<CreateUserProfileEvent>(_onCreateUserProfile);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
  }

  Future<void> _onCreateUserProfile(
    CreateUserProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    LoggingService.logFirestore('UserBloc: Creating user profile for ${event.phoneNumber}');
    emit(state.copyWithLoading());

    try {
      final result = await _userRepository.createUser(
        phoneNumber: event.phoneNumber,
        name: event.name,
        email: event.email,
        isOptedInForMarketing: event.isOptedInForMarketing,
      );

      await result.fold(
        (failure) async {
          LoggingService.logError('UserBloc: Failed to create user', failure.message);
          if (!emit.isDone) emit(state.copyWithError(failure.message));
        },
        (user) async {
          LoggingService.logFirestore('UserBloc: User profile created successfully for ${user.name}');
          
          // After creating the user profile, explicitly load it as well
          // This ensures the data is available in both the repository and local services
          if (!emit.isDone) {
            // First emit the created state
            emit(state.copyWithCreated(user));
            
            // Then try to reload the user data to ensure it's fully available
            try {
              await _userRepository.getUserById(user.id);
              LoggingService.logFirestore('UserBloc: Refreshed user data after creation');
            } catch (e) {
              // Ignore any errors here, as we already have the user data from creation
              LoggingService.logError('UserBloc', 'Error refreshing user after creation: $e');
            }
          }
        },
      );
    } catch (e) {
      LoggingService.logError('UserBloc: Exception during user creation', e.toString());
      if (!emit.isDone) emit(state.copyWithError('Failed to create user profile: $e'));
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    LoggingService.logFirestore('UserBloc: Loading user profile for ${event.userId}');
    emit(state.copyWithLoading());

    try {
      final result = await _userRepository.getUserById(event.userId);

      await result.fold(
        (failure) async {
          LoggingService.logError('UserBloc: Failed to load user', failure.message);
          if (!emit.isDone) emit(state.copyWithError(failure.message));
        },
        (user) async {
          LoggingService.logFirestore('UserBloc: User profile loaded successfully');
          if (!emit.isDone) emit(state.copyWithLoaded(user));
        },
      );
    } catch (e) {
      LoggingService.logError('UserBloc: Exception during user loading', e.toString());
      if (!emit.isDone) emit(state.copyWithError('Failed to load user profile: $e'));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    // Make sure we have a user to update
    if (state.user == null) {
      emit(state.copyWithError('No user profile loaded to update'));
      return;
    }

    LoggingService.logFirestore('UserBloc: Updating user profile for ${state.user!.id}');
    emit(state.copyWithLoading());

    try {
      final result = await _userRepository.updateUser(
        userId: state.user!.id,
        name: event.name,
        email: event.email,
        isOptedInForMarketing: event.isOptedInForMarketing,
      );

      await result.fold(
        (failure) async {
          LoggingService.logError('UserBloc: Failed to update user', failure.message);
          if (!emit.isDone) emit(state.copyWithError(failure.message));
        },
        (user) async {
          LoggingService.logFirestore('UserBloc: User profile updated successfully');
          if (!emit.isDone) emit(state.copyWithUpdated(user));
        },
      );
    } catch (e) {
      LoggingService.logError('UserBloc: Exception during user update', e.toString());
      if (!emit.isDone) emit(state.copyWithError('Failed to update user profile: $e'));
    }
  }
}
