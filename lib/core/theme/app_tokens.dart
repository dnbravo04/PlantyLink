import 'package:flutter/material.dart';

/// Centralized design tokens for consistent spacing, radius, shadows,
/// durations, and curves across all PlantyLink widgets.
sealed class AppTokens {
  AppTokens._();

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spacingXs  = 4;
  static const double spacingSm  = 8;
  static const double spacingMd  = 16;
  static const double spacingLg  = 24;
  static const double spacingXl  = 32;
  static const double spacingXxl = 48;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusSm   = 8;
  static const double radiusMd   = 12;
  static const double radiusLg   = 16;
  static const double radiusXl   = 20;
  static const double radiusXxl  = 24;
  static const double radiusPill = 999;

  // ── Box Shadows ───────────────────────────────────────────────────────────
  static List<BoxShadow> shadowSubtle(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowElevated(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration durationMicro    = Duration(milliseconds: 100);
  static const Duration durationFast     = Duration(milliseconds: 200);
  static const Duration durationNormal   = Duration(milliseconds: 300);
  static const Duration durationSlow     = Duration(milliseconds: 500);
  static const Duration durationEntrance = Duration(milliseconds: 800);

  // ── Animation Curves ──────────────────────────────────────────────────────
  static const Curve curveSnappy = Curves.easeOutCubic;
  static const Curve curveSmooth = Curves.easeInOut;
  static const Curve curveBounce = Curves.elasticOut;

  // ── Stagger delay per card index ──────────────────────────────────────────
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: 80 * index);
}
