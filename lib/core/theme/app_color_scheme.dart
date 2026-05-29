import 'package:flutter/material.dart';

/// A fully typed color palette that supports both dark and light themes.
/// Use [AppColors.of(context)] to get the current theme's instance.
class AppColorScheme {
  final Brightness brightness;
  final Color background;
  final Color cardBackground;
  final Color cardBorder;
  final Color primary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  const AppColorScheme({
    required this.brightness,
    required this.background,
    required this.cardBackground,
    required this.cardBorder,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
  });

  bool get isDark => brightness == Brightness.dark;
}
