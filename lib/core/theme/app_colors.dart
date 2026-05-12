import 'package:flutter/material.dart';

/// Centralized color palette for HydroTracker.
/// All UI colors should be referenced from here to maintain consistency.
sealed class AppColors {
  AppColors._();

  // Background & surfaces
  static const Color background = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color cardBorder = Color(0xFF30363D);

  // Semantic colors
  static const Color primary = Color(0xFF238636);
  static const Color success = Color(0xFF2EA043);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);
  static const Color accent = Color(0xFF238636);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
  static const Color textDisabled = Color(0xFF30363D);
}
