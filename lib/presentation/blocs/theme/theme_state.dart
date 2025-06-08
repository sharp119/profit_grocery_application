import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState(this.themeMode);

  factory ThemeState.initial() {
    return const ThemeState(ThemeMode.dark); // Default to dark theme
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => [themeMode];
}