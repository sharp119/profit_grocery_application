import 'package:flutter/material.dart';

abstract class ThemeEvent {
  const ThemeEvent();
}

class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

class ToggleTheme extends ThemeEvent {
  final bool isLight;
  const ToggleTheme(this.isLight);
}