import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _sharedPreferences;

  ThemeBloc({required SharedPreferences sharedPreferences})
      : _sharedPreferences = sharedPreferences,
        super(ThemeState.initial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(
      LoadTheme event, Emitter<ThemeState> emit) async {
    // Retrieve the saved theme mode from SharedPreferences
    // The index of the enum value is stored (0 for system, 1 for light, 2 for dark)
    final int? themeIndex = _sharedPreferences.getInt(AppConstants.themeModeKey);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      emit(state.copyWith(themeMode: ThemeMode.values[themeIndex]));
    } else {
      // Default to dark if no theme is saved or the saved value is invalid
      emit(state.copyWith(themeMode: ThemeMode.dark));
    }
  }

  Future<void> _onToggleTheme(
      ToggleTheme event, Emitter<ThemeState> emit) async {
    final newThemeMode = event.isLight ? ThemeMode.light : ThemeMode.dark;
    // Save the new theme mode's index
    await _sharedPreferences.setInt(AppConstants.themeModeKey, newThemeMode.index);
    emit(state.copyWith(themeMode: newThemeMode));
  }
}